--liquibase formatted sql
--changeset postgresto:fn-manage_update_timestamp runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
-- Inspect or manage a table's updated_at BEFORE UPDATE trigger.
--
-- SELECT postgresto.manage_update_timestamp('docs', 'demo');        -- inspect (STABLE)
-- SELECT postgresto.manage_update_timestamp('docs', 'demo', true);  -- enable (VOLATILE)
-- SELECT postgresto.manage_update_timestamp('docs', 'demo', false); -- disable (VOLATILE)
DROP FUNCTION IF EXISTS postgresto.manage_update_timestamp(text, text, boolean);
DROP FUNCTION IF EXISTS postgresto.manage_update_timestamp(text, text);

CREATE OR REPLACE FUNCTION postgresto.manage_update_timestamp(
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
  v_has_updated_at boolean;
BEGIN
  IF v_schema IS NULL OR v_schema = '' THEN
    RAISE EXCEPTION 'schema name is required';
  END IF;
  IF p_table IS NULL OR btrim(p_table) = '' THEN
    RAISE EXCEPTION 'table name is required';
  END IF;

  p_table := btrim(p_table);
  IF p_table LIKE '%\_history' ESCAPE '\' THEN
    RAISE EXCEPTION 'history tables cannot manage update_timestamp: %', p_table;
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

  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = v_schema
      AND table_name = p_table
      AND column_name = 'updated_at'
  ) INTO v_has_updated_at;

  v_trigger_name := 'update_timestamp_' || p_table;

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
    'schema', v_schema,
    'trigger', v_trigger_name,
    'trigger_enabled', COALESCE(v_trigger_enabled, false),
    'has_updated_at', COALESCE(v_has_updated_at, false)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION postgresto.manage_update_timestamp(
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
  v_status jsonb;
  v_has_updated_at boolean;
BEGIN
  IF p_enabled IS NULL THEN
    RAISE EXCEPTION 'p_enabled is required to change update_timestamp';
  END IF;

  v_status := postgresto.manage_update_timestamp(v_schema, btrim(p_table));
  v_trigger_name := v_status ->> 'trigger';
  v_has_updated_at := COALESCE((v_status ->> 'has_updated_at')::boolean, false);
  v_schema := v_status ->> 'schema';
  p_table := v_status ->> 'table';

  IF p_enabled IS TRUE THEN
    IF NOT v_has_updated_at THEN
      RAISE EXCEPTION 'table %.% has no updated_at column', v_schema, p_table;
    END IF;
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', v_trigger_name, v_schema, p_table);
    EXECUTE format(
      'CREATE TRIGGER %I
        BEFORE UPDATE ON %I.%I
        FOR EACH ROW
        EXECUTE FUNCTION postgresto.update_timestamp()',
      v_trigger_name,
      v_schema,
      p_table
    );
    PERFORM pg_notify('pgrst', 'reload schema');
  ELSE
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', v_trigger_name, v_schema, p_table);
    PERFORM pg_notify('pgrst', 'reload schema');
  END IF;

  RETURN postgresto.manage_update_timestamp(v_schema, p_table);
END;
$function$;
