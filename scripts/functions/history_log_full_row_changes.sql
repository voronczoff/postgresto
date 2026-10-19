--liquibase formatted sql
--changeset postgresto:fn-history_log_full_row_changes runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
-- Log relational rows without a jsondata column as complete JSON snapshots.
-- The companion history table retains the standard (id, jsondata) schema.
DROP FUNCTION IF EXISTS postgresto.write_full_row_history(text, text, jsonb, text);
CREATE OR REPLACE FUNCTION postgresto.write_full_row_history(
  p_schema text,
  p_table text,
  p_source_row jsonb,
  p_operation text,
  p_source_id text
)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  event_ts timestamptz := clock_timestamp();
  event_ts_text text;
  history_id_suffix text;
  source_id text;
BEGIN
  source_id := p_source_id;
  IF source_id IS NULL THEN
    RAISE EXCEPTION 'table %.% requires a non-null primary key for history', p_schema, p_table;
  END IF;

  event_ts_text := to_char(event_ts AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
  history_id_suffix := to_char(event_ts AT TIME ZONE 'UTC', 'YYYYMMDDHH24MISSUS');
  EXECUTE format(
    'INSERT INTO %I.%I (id, jsondata) VALUES ($1, $2)',
    p_schema, p_table || '_history'
  ) USING
    source_id || '|' || history_id_suffix,
    p_source_row || jsonb_build_object(
      '$operationType', p_operation,
      '$transactionDate', event_ts_text
    );
END;
$function$;

CREATE OR REPLACE FUNCTION postgresto.history_log_full_row_changes()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  table_exists boolean;
  source_row jsonb;
  old_row jsonb;
  new_row jsonb;
  operation_type text;
  old_source_id text;
  new_source_id text;
  source_id text;
  pk_count integer;
  audit_keys text[] := ARRAY['updated_at', 'updated_by', 'created_at', 'created_by', 'request_id'];
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_tables
    WHERE schemaname = TG_TABLE_SCHEMA AND tablename = TG_TABLE_NAME || '_history'
  ) INTO table_exists;
  IF NOT table_exists THEN
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  END IF;

  old_row := CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) END;
  new_row := CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) END;
  SELECT count(*) INTO pk_count
  FROM pg_index index_def
  JOIN unnest(index_def.indkey) WITH ORDINALITY AS key_def(attnum, ordinality) ON TRUE
  JOIN pg_attribute attribute_def
    ON attribute_def.attrelid = index_def.indrelid
    AND attribute_def.attnum = key_def.attnum
  WHERE index_def.indrelid = TG_RELID AND index_def.indisprimary;

  IF pk_count = 0 THEN
    RAISE EXCEPTION 'table %.% requires a primary key for history', TG_TABLE_SCHEMA, TG_TABLE_NAME;
  END IF;

  SELECT CASE WHEN pk_count = 1 THEN max(row_data ->> column_name)
              ELSE jsonb_object_agg(column_name, row_data -> column_name)::text END
  INTO old_source_id
  FROM (
    SELECT attribute_def.attname AS column_name, old_row AS row_data
    FROM pg_index index_def
    JOIN unnest(index_def.indkey) WITH ORDINALITY AS key_def(attnum, ordinality) ON TRUE
    JOIN pg_attribute attribute_def
      ON attribute_def.attrelid = index_def.indrelid
      AND attribute_def.attnum = key_def.attnum
    WHERE index_def.indrelid = TG_RELID AND index_def.indisprimary
  ) primary_key;
  SELECT CASE WHEN pk_count = 1 THEN max(row_data ->> column_name)
              ELSE jsonb_object_agg(column_name, row_data -> column_name)::text END
  INTO new_source_id
  FROM (
    SELECT attribute_def.attname AS column_name, new_row AS row_data
    FROM pg_index index_def
    JOIN unnest(index_def.indkey) WITH ORDINALITY AS key_def(attnum, ordinality) ON TRUE
    JOIN pg_attribute attribute_def
      ON attribute_def.attrelid = index_def.indrelid
      AND attribute_def.attnum = key_def.attnum
    WHERE index_def.indrelid = TG_RELID AND index_def.indisprimary
  ) primary_key;

  IF TG_OP = 'UPDATE' THEN
    IF old_row - audit_keys IS NOT DISTINCT FROM new_row - audit_keys THEN
      RETURN NEW;
    END IF;
    IF old_source_id IS DISTINCT FROM new_source_id THEN
      PERFORM postgresto.write_full_row_history(TG_TABLE_SCHEMA, TG_TABLE_NAME, old_row, 'DELETE', old_source_id);
      PERFORM postgresto.write_full_row_history(TG_TABLE_SCHEMA, TG_TABLE_NAME, new_row, 'CREATE', new_source_id);
      RETURN NEW;
    END IF;
  END IF;

  operation_type := CASE TG_OP
    WHEN 'INSERT' THEN 'CREATE'
    WHEN 'UPDATE' THEN 'UPDATE'
    WHEN 'DELETE' THEN 'DELETE'
  END;
  source_row := CASE WHEN TG_OP = 'DELETE' THEN old_row ELSE new_row END;
  source_id := CASE WHEN TG_OP = 'DELETE' THEN old_source_id ELSE new_source_id END;
  PERFORM postgresto.write_full_row_history(
    TG_TABLE_SCHEMA, TG_TABLE_NAME, source_row, operation_type, source_id
  );
  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$function$;
