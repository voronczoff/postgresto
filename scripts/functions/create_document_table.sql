--liquibase formatted sql
--changeset postgresto:fn-create_document_table runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
-- Create a document table with the fixed postgresto schema
-- (id, jsondata, created_at/by, updated_at/by), optionally attaching
-- update_timestamp, set_audit_user, search-index, and history triggers.
--
-- SELECT postgresto.create_document_table('docs');
-- SELECT postgresto.create_document_table('docs', true, true, 'postgresto');
-- SELECT postgresto.create_document_table('docs', true, true, 'postgresto', true);
-- SELECT postgresto.create_document_table('docs', true, true, 'postgresto', true, true);
DROP FUNCTION IF EXISTS postgresto.create_document_table(text, boolean, boolean, text);
DROP FUNCTION IF EXISTS postgresto.create_document_table(text, boolean, boolean, text, boolean);
DROP FUNCTION IF EXISTS postgresto.create_document_table(text, boolean, boolean, text, boolean, boolean);
CREATE OR REPLACE FUNCTION postgresto.create_document_table(
  p_table text,
  p_update_timestamp boolean DEFAULT true,
  p_search boolean DEFAULT true,
  p_schema text DEFAULT 'postgresto',
  p_history boolean DEFAULT true,
  p_audit_user boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
AS $function$
DECLARE
  v_schema text := btrim(COALESCE(p_schema, 'postgresto'));
  v_table text := btrim(p_table);
  v_update_timestamp boolean := COALESCE(p_update_timestamp, true);
  v_search boolean := COALESCE(p_search, true);
  v_history boolean := COALESCE(p_history, true);
  v_audit_user boolean := COALESCE(p_audit_user, true);
  v_ts_trigger text;
  v_audit_trigger text;
  v_search_status jsonb;
  v_history_status jsonb;
BEGIN
  IF v_schema IS NULL OR v_schema = '' THEN
    RAISE EXCEPTION 'schema name is required';
  END IF;
  IF v_table IS NULL OR v_table = '' THEN
    RAISE EXCEPTION 'table name is required';
  END IF;
  IF v_table !~ '^[a-zA-Z_][a-zA-Z0-9_]*$' THEN
    RAISE EXCEPTION 'invalid table name: %', v_table;
  END IF;
  IF length(v_table) > 50 THEN
    RAISE EXCEPTION 'table name is too long (max 50): %', v_table;
  END IF;
  IF v_table LIKE '%\_history' ESCAPE '\' THEN
    RAISE EXCEPTION 'cannot create a history table directly: %', v_table;
  END IF;
  IF v_table = '${search.table}' THEN
    RAISE EXCEPTION 'cannot create the search index table via create_document_table';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_namespace
    WHERE nspname = v_schema
  ) THEN
    RAISE EXCEPTION 'schema % does not exist', v_schema;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = v_schema
      AND table_name = v_table
  ) THEN
    RAISE EXCEPTION 'table %.% already exists', v_schema, v_table;
  END IF;

  EXECUTE format(
    'CREATE TABLE %I.%I (
      id          text        NOT NULL,
      jsondata    jsonb       NOT NULL DEFAULT ''{}''::jsonb,
      created_at  timestamptz NOT NULL DEFAULT now(),
      updated_at  timestamptz NOT NULL DEFAULT now(),
      created_by  text,
      updated_by  text,
      CONSTRAINT %I PRIMARY KEY (id)
    )',
    v_schema,
    v_table,
    v_table || '_pkey'
  );

  v_ts_trigger := 'update_timestamp_' || v_table;
  IF v_update_timestamp THEN
    EXECUTE format(
      'CREATE TRIGGER %I
        BEFORE UPDATE ON %I.%I
        FOR EACH ROW
        EXECUTE FUNCTION postgresto.update_timestamp()',
      v_ts_trigger,
      v_schema,
      v_table
    );
  END IF;

  v_audit_trigger := 'set_audit_user_' || v_table;
  IF v_audit_user THEN
    EXECUTE format(
      'CREATE TRIGGER %I
        BEFORE INSERT OR UPDATE ON %I.%I
        FOR EACH ROW
        EXECUTE FUNCTION postgresto.set_audit_user()',
      v_audit_trigger,
      v_schema,
      v_table
    );
  END IF;

  IF v_search THEN
    v_search_status := postgresto.manage_search_table(v_schema, v_table, true);
  ELSE
    v_search_status := jsonb_build_object(
      'table', v_table,
      'schema', v_schema,
      'trigger', v_table || '_trg_search_index',
      'trigger_enabled', false,
      'indexed', false
    );
  END IF;

  IF v_history THEN
    v_history_status := postgresto.manage_history_table(v_schema, v_table, true);
  ELSE
    v_history_status := jsonb_build_object(
      'table', v_table,
      'history_table', v_table || '_history',
      'history_exists', false,
      'trigger', v_table || '_trg_log_history',
      'trigger_enabled', false
    );
  END IF;

  PERFORM pg_notify('pgrst', 'reload schema');

  RETURN jsonb_build_object(
    'schema', v_schema,
    'table', v_table,
    'update_timestamp', v_update_timestamp,
    'update_timestamp_trigger', CASE WHEN v_update_timestamp THEN v_ts_trigger ELSE NULL END,
    'audit_user', v_audit_user,
    'audit_user_trigger', CASE WHEN v_audit_user THEN v_audit_trigger ELSE NULL END,
    'search', v_search,
    'search_status', v_search_status,
    'history', v_history,
    'history_status', v_history_status
  );
END;
$function$;
