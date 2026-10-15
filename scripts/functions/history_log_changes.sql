--liquibase formatted sql
--changeset postgresto:fn-history_log_changes runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
-- Log row changes into the source schema's <table>_history (when it exists).
-- Prefer jsondata snapshot when present; otherwise to_jsonb(row).
-- Skip UPDATE when jsondata (or non-audit row) is unchanged, ignoring volatile keys.
-- Primary-key changes are logged as DELETE of the old id + CREATE of the new id.

-- Move legacy public.history_log_changes into postgresto when present so existing
-- triggers keep the same function OID; drop public only if both already exist.
DO $migrate$
BEGIN
  IF to_regprocedure('public.history_log_changes()') IS NOT NULL THEN
    IF to_regprocedure('postgresto.history_log_changes()') IS NULL THEN
      ALTER FUNCTION public.history_log_changes() SET SCHEMA postgresto;
    ELSE
      DROP FUNCTION public.history_log_changes() CASCADE;
    END IF;
  END IF;
END
$migrate$;

CREATE OR REPLACE FUNCTION postgresto.history_log_changes()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    history_table text := format('%I.%I', TG_TABLE_SCHEMA, TG_TABLE_NAME || '_history');
    table_exists boolean;
    has_jsondata boolean;
    operation_type TEXT;
    snapshot JSONB;
    jsondata_with_operation JSONB;
    old_payload JSONB;
    new_payload JSONB;
    source_row JSONB;
    source_primary_key TEXT;
    pk_changed boolean := false;
    event_ts timestamptz;
    event_ts_text text;
    history_id_suffix text;
    audit_keys text[] := ARRAY[
      'updated_at', 'updated_by', 'created_at', 'created_by', 'request_id'
    ];
    -- Volatile keys inside jsondata that should not alone create a history row.
    jsondata_ignore_keys text[] := ARRAY[
      'UpdateTime', '$updatedAt', '$transactionDate', '$updatedBy'
    ];
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = TG_TABLE_SCHEMA
          AND table_name = TG_TABLE_NAME
          AND column_name = 'jsondata'
    ) INTO has_jsondata;

    SELECT EXISTS (
        SELECT 1 FROM pg_tables
        WHERE schemaname = TG_TABLE_SCHEMA AND tablename = TG_TABLE_NAME || '_history'
    ) INTO table_exists;

    IF NOT table_exists THEN
        RETURN CASE WHEN (TG_OP = 'DELETE') THEN OLD ELSE NEW END;
    END IF;

    /*
     * A history row must remain tied to the source row even when its
     * primary key is not named `id`. Keep the existing scalar format for
     * single-column keys; serialize composite keys as a stable JSON value.
     */
    IF TG_OP = 'UPDATE' THEN
        SELECT
            CASE
                WHEN count(*) = 0 THEN NULL
                WHEN bool_or(
                    to_jsonb(OLD) -> column_name IS DISTINCT FROM
                    to_jsonb(NEW) -> column_name
                ) THEN true
                ELSE false
            END
        INTO pk_changed
        FROM (
            SELECT attribute_def.attname AS column_name
            FROM pg_index index_def
            JOIN unnest(index_def.indkey) WITH ORDINALITY
                AS key_def(attnum, ordinality) ON TRUE
            JOIN pg_attribute attribute_def
                ON attribute_def.attrelid = index_def.indrelid
                AND attribute_def.attnum = key_def.attnum
            WHERE index_def.indrelid = TG_RELID
              AND index_def.indisprimary
        ) primary_key;

        IF pk_changed IS NULL THEN
            RAISE EXCEPTION 'table %.% requires a primary key for history',
                TG_TABLE_SCHEMA, TG_TABLE_NAME;
        END IF;
    END IF;

    -- On UPDATE with unchanged primary key, skip history when content did not
    -- meaningfully change. Primary-key changes always write DELETE + CREATE.
    IF TG_OP = 'UPDATE' AND NOT pk_changed THEN
        IF has_jsondata THEN
            old_payload := COALESCE(OLD.jsondata, '{}'::jsonb) - jsondata_ignore_keys;
            new_payload := COALESCE(NEW.jsondata, '{}'::jsonb) - jsondata_ignore_keys;
        ELSE
            old_payload := to_jsonb(OLD) - audit_keys;
            new_payload := to_jsonb(NEW) - audit_keys;
        END IF;
        IF old_payload IS NOT DISTINCT FROM new_payload THEN
            RETURN NEW;
        END IF;
    END IF;

    IF pk_changed THEN
        -- DELETE snapshot for the original identity, then CREATE for the new one.
        FOREACH operation_type IN ARRAY ARRAY['DELETE', 'CREATE']
        LOOP
            source_row := CASE
                WHEN operation_type = 'DELETE' THEN to_jsonb(OLD)
                ELSE to_jsonb(NEW)
            END;

            IF has_jsondata THEN
                snapshot := COALESCE(
                    CASE
                        WHEN operation_type = 'DELETE' THEN OLD.jsondata
                        ELSE NEW.jsondata
                    END,
                    '{}'::jsonb
                );
            ELSE
                snapshot := source_row;
            END IF;

            event_ts := clock_timestamp();
            event_ts_text := to_char(
                event_ts AT TIME ZONE 'UTC',
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
            );
            history_id_suffix := TO_CHAR(
                event_ts AT TIME ZONE 'UTC',
                'YYYYMMDDHH24MISSUS'
            );

            SELECT CASE
                WHEN count(*) = 1 THEN max(source_row ->> column_name)
                ELSE jsonb_object_agg(column_name, source_row -> column_name)::text
            END
            INTO source_primary_key
            FROM (
                SELECT attribute_def.attname AS column_name
                FROM pg_index index_def
                JOIN unnest(index_def.indkey) WITH ORDINALITY
                    AS key_def(attnum, ordinality) ON TRUE
                JOIN pg_attribute attribute_def
                    ON attribute_def.attrelid = index_def.indrelid
                    AND attribute_def.attnum = key_def.attnum
                WHERE index_def.indrelid = TG_RELID
                  AND index_def.indisprimary
            ) primary_key;

            IF source_primary_key IS NULL THEN
                RAISE EXCEPTION 'table %.% requires a primary key for history',
                    TG_TABLE_SCHEMA, TG_TABLE_NAME;
            END IF;

            jsondata_with_operation := snapshot
                || jsonb_build_object('$operationType', operation_type)
                || jsonb_build_object('$transactionDate', event_ts_text);

            EXECUTE format(
                'INSERT INTO %s (id, jsondata) VALUES ($1, $2)',
                history_table
            )
            USING
                source_primary_key || '|' || history_id_suffix,
                jsondata_with_operation;
        END LOOP;

        RETURN NEW;
    END IF;

    operation_type := CASE
        WHEN TG_OP = 'INSERT' THEN 'CREATE'
        WHEN TG_OP = 'UPDATE' THEN 'UPDATE'
        WHEN TG_OP = 'DELETE' THEN 'DELETE'
        ELSE NULL
    END;

    source_row := CASE
        WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD)
        ELSE to_jsonb(NEW)
    END;

    IF has_jsondata THEN
        snapshot := COALESCE(
            CASE WHEN TG_OP = 'DELETE' THEN OLD.jsondata ELSE NEW.jsondata END,
            '{}'::jsonb
        );
    ELSE
        snapshot := CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(NEW) END;
    END IF;

    event_ts := clock_timestamp();
    event_ts_text := to_char(
        event_ts AT TIME ZONE 'UTC',
        'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
    );
    history_id_suffix := TO_CHAR(
        event_ts AT TIME ZONE 'UTC',
        'YYYYMMDDHH24MISSUS'
    );

    jsondata_with_operation := snapshot
        || jsonb_build_object('$operationType', operation_type)
        || jsonb_build_object('$transactionDate', event_ts_text);

    SELECT CASE
        WHEN count(*) = 1 THEN max(source_row ->> column_name)
        ELSE jsonb_object_agg(column_name, source_row -> column_name)::text
    END
    INTO source_primary_key
    FROM (
        SELECT attribute_def.attname AS column_name
        FROM pg_index index_def
        JOIN unnest(index_def.indkey) WITH ORDINALITY
            AS key_def(attnum, ordinality) ON TRUE
        JOIN pg_attribute attribute_def
            ON attribute_def.attrelid = index_def.indrelid
            AND attribute_def.attnum = key_def.attnum
        WHERE index_def.indrelid = TG_RELID
          AND index_def.indisprimary
    ) primary_key;

    IF source_primary_key IS NULL THEN
        RAISE EXCEPTION 'table %.% requires a primary key for history',
            TG_TABLE_SCHEMA, TG_TABLE_NAME;
    END IF;

    EXECUTE format(
        'INSERT INTO %s (id, jsondata) VALUES ($1, $2)',
        history_table
    )
    USING
        source_primary_key || '|' || history_id_suffix,
        jsondata_with_operation;

    RETURN CASE WHEN (TG_OP = 'DELETE') THEN OLD ELSE NEW END;
END;
$function$;
