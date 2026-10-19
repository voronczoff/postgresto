--liquibase formatted sql
--changeset postgresto:fn-manage_search_table runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
-- Inspect or manage a table's search-index CRUD trigger.
--
-- SELECT postgresto.manage_search_table('docs', 'demo');        -- inspect (STABLE)
-- SELECT postgresto.manage_search_table('docs', 'demo', true);  -- enable (VOLATILE)
-- SELECT postgresto.manage_search_table('docs', 'demo', false); -- disable (VOLATILE)
DROP FUNCTION IF EXISTS postgresto.search_manage_table(text, text, boolean);
DROP FUNCTION IF EXISTS postgresto.search_manage_table(text, text);
DROP FUNCTION IF EXISTS postgresto.manage_search_table(text, text, boolean);
DROP FUNCTION IF EXISTS postgresto.manage_search_table(text, text);

CREATE OR REPLACE FUNCTION postgresto.manage_search_table(
  p_schema text,
  p_table text
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $function$
DECLARE
  v_schema text := btrim(p_schema);
  v_trigger_name text;
  v_trigger_enabled boolean;
  v_full_name text;
  v_indexed boolean;
BEGIN
  IF v_schema IS NULL OR v_schema = '' THEN
    RAISE EXCEPTION 'schema name is required';
  END IF;
  IF p_table IS NULL OR btrim(p_table) = '' THEN
    RAISE EXCEPTION 'table name is required';
  END IF;

  p_table := btrim(p_table);
  IF p_table = 'search' THEN
    RAISE EXCEPTION 'search index table cannot manage its own search trigger';
  END IF;
  IF p_table LIKE '%\_history' ESCAPE '\' THEN
    RAISE EXCEPTION 'history tables cannot be search-indexed via trigger: %', p_table;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = v_schema
      AND table_name = p_table
      AND table_type = 'BASE TABLE'
  ) THEN
    RAISE EXCEPTION 'table %.% does not exist or is not a base table', v_schema, p_table;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_index index_def
    JOIN pg_class table_def ON table_def.oid = index_def.indrelid
    JOIN pg_namespace schema_def ON schema_def.oid = table_def.relnamespace
    WHERE schema_def.nspname = v_schema
      AND table_def.relname = p_table
      AND index_def.indisprimary
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = v_schema
      AND table_name = p_table
      AND column_name = 'id'
  ) THEN
    RAISE EXCEPTION 'table %.% requires a primary key or id column for search', v_schema, p_table;
  END IF;

  v_trigger_name := p_table || '_trg_search_index';
  v_full_name := v_schema || '.' || p_table;

  SELECT EXISTS (
    SELECT 1
    FROM pg_trigger trigger_def
    JOIN pg_class table_def ON table_def.oid = trigger_def.tgrelid
    JOIN pg_namespace schema_def ON schema_def.oid = table_def.relnamespace
    WHERE schema_def.nspname = v_schema
      AND table_def.relname = p_table
      AND trigger_def.tgname = v_trigger_name
      AND NOT trigger_def.tgisinternal
      AND trigger_def.tgenabled <> 'D'
  ) INTO v_trigger_enabled;

  SELECT
    jsonb_typeof(c.jsondata -> 'index') = 'object'
    AND (c.jsondata -> 'index' -> v_full_name) = 'true'::jsonb
  INTO v_indexed
  FROM postgresto.config c
  WHERE c.id = 'index';

  RETURN jsonb_build_object(
    'table', p_table,
    'schema', v_schema,
    'trigger', v_trigger_name,
    'trigger_enabled', COALESCE(v_trigger_enabled, false),
    'indexed', COALESCE(v_indexed, false)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION postgresto.manage_search_table(
  p_schema text,
  p_table text,
  p_enabled boolean
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
AS $function$
DECLARE
  v_schema text := btrim(p_schema);
  v_trigger_name text;
  v_full_name text;
  v_status jsonb;
BEGIN
  IF p_enabled IS NULL THEN
    RAISE EXCEPTION 'p_enabled is required to change search indexing';
  END IF;

  v_status := postgresto.manage_search_table(v_schema, btrim(p_table));
  p_table := v_status ->> 'table';
  v_schema := v_status ->> 'schema';
  v_trigger_name := v_status ->> 'trigger';
  v_full_name := v_schema || '.' || p_table;

  IF p_enabled IS TRUE THEN
    -- Ensure allowlist entry so search_log_changes and search_refresh include the table.
    INSERT INTO postgresto.config (id, jsondata)
    VALUES ('index', jsonb_build_object('index', jsonb_build_object(v_full_name, true)))
    ON CONFLICT (id) DO UPDATE
    SET jsondata = jsonb_set(
      COALESCE(jsondata, '{}'::jsonb),
      '{index}',
      COALESCE(jsondata -> 'index', '{}'::jsonb) || jsonb_build_object(v_full_name, true),
      true
    );

    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', v_trigger_name, v_schema, p_table);
    EXECUTE format(
      'CREATE TRIGGER %I
        AFTER INSERT OR UPDATE OR DELETE ON %I.%I
        FOR EACH ROW
        EXECUTE FUNCTION postgresto.search_log_changes()',
      v_trigger_name,
      v_schema,
      p_table
    );
    PERFORM pg_notify('pgrst', 'reload schema');
  ELSE
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', v_trigger_name, v_schema, p_table);
    PERFORM pg_notify('pgrst', 'reload schema');
  END IF;

  RETURN postgresto.manage_search_table(v_schema, p_table);
END;
$function$;
