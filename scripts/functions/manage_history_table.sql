--liquibase formatted sql
--changeset postgresto:fn-manage_history_table runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
-- Inspect or manage a table's history companion and change-log trigger.
--
-- SELECT postgresto.manage_history_table('docs', 'demo');        -- inspect (STABLE)
-- SELECT postgresto.manage_history_table('docs', 'demo', true);  -- enable (VOLATILE)
-- SELECT postgresto.manage_history_table('docs', 'demo', false); -- disable (VOLATILE)
DROP FUNCTION IF EXISTS postgresto.manage_history_table(text, boolean);
DROP FUNCTION IF EXISTS postgresto.manage_history_table(text, text, boolean);
DROP FUNCTION IF EXISTS postgresto.manage_history_table(text, text);

CREATE OR REPLACE FUNCTION postgresto.manage_history_table(
  p_schema text,
  p_table text
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $function$
DECLARE
  v_schema text := btrim(p_schema);
  v_history_table text;
  v_trigger_name text;
  v_history_exists boolean;
  v_trigger_enabled boolean;
  v_has_jsondata boolean;
  v_log_function text;
BEGIN
  IF v_schema IS NULL OR v_schema = '' THEN
    RAISE EXCEPTION 'schema name is required';
  END IF;
  IF p_table IS NULL OR btrim(p_table) = '' THEN
    RAISE EXCEPTION 'table name is required';
  END IF;

  p_table := btrim(p_table);
  IF p_table LIKE '%\_history' ESCAPE '\' THEN
    RAISE EXCEPTION 'history tables cannot manage their own history: %', p_table;
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
  ) THEN
    RAISE EXCEPTION 'table %.% requires a primary key for history', v_schema, p_table;
  END IF;

  v_history_table := p_table || '_history';
  v_trigger_name := p_table || '_trg_log_history';

  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = v_schema
      AND table_name = p_table
      AND column_name = 'jsondata'
  ) INTO v_has_jsondata;
  v_log_function := CASE
    WHEN v_has_jsondata THEN 'history_log_changes'
    ELSE 'history_log_full_row_changes'
  END;

  SELECT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = v_schema
      AND table_name = v_history_table
      AND table_type = 'BASE TABLE'
  ) INTO v_history_exists;

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

  RETURN jsonb_build_object(
    'table', p_table,
    'history_table', v_history_table,
    'history_exists', v_history_exists,
    'trigger', v_trigger_name,
    'trigger_enabled', v_trigger_enabled,
    'logger', v_log_function
  );
END;
$function$;

CREATE OR REPLACE FUNCTION postgresto.manage_history_table(
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
  v_history_table text;
  v_trigger_name text;
  v_log_function text;
  v_status jsonb;
  v_has_jsondata boolean;
BEGIN
  IF p_enabled IS NULL THEN
    RAISE EXCEPTION 'p_enabled is required to change history logging';
  END IF;

  v_status := postgresto.manage_history_table(v_schema, btrim(p_table));
  p_table := v_status ->> 'table';
  v_history_table := v_status ->> 'history_table';
  v_trigger_name := v_status ->> 'trigger';

  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = v_schema
      AND table_name = p_table
      AND column_name = 'jsondata'
  ) INTO v_has_jsondata;
  v_log_function := CASE
    WHEN v_has_jsondata THEN 'history_log_changes'
    ELSE 'history_log_full_row_changes'
  END;

  IF p_enabled IS TRUE THEN
    EXECUTE format(
      'CREATE TABLE IF NOT EXISTS %I.%I (
        id text PRIMARY KEY,
        jsondata jsonb NOT NULL DEFAULT ''{}''::jsonb
      )',
      v_schema,
      v_history_table
    );
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', v_trigger_name, v_schema, p_table);
    EXECUTE format(
      'CREATE TRIGGER %I
        AFTER INSERT OR UPDATE OR DELETE ON %I.%I
        FOR EACH ROW
        EXECUTE FUNCTION postgresto.%I()',
      v_trigger_name,
      v_schema,
      p_table,
      v_log_function
    );
    -- Publish the newly created companion table and its trigger to PostgREST.
    PERFORM pg_notify('pgrst', 'reload schema');
  ELSE
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', v_trigger_name, v_schema, p_table);
    PERFORM pg_notify('pgrst', 'reload schema');
  END IF;

  RETURN postgresto.manage_history_table(v_schema, p_table);
END;
$function$;
