--liquibase formatted sql
--changeset postgresto:fn-search_log_changes runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
-- Keep postgresto.search in sync for one source row after INSERT/UPDATE/DELETE.
-- Uses the same tsvector shape as search_refresh (jsonb_to_tsvector on to_jsonb(row)).
-- Primary-key changes remove the old search id and upsert the new one.

CREATE OR REPLACE FUNCTION postgresto.search_log_changes()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  v_full_name text := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME;
  v_search_table text := 'postgresto.${search.table}';
  v_row jsonb;
  v_id text;
  v_old_id text;
  v_indexed boolean;
  pk_changed boolean := false;
BEGIN
  -- Only index tables present in config row id=index with value true.
  SELECT
    jsonb_typeof(c.jsondata -> 'index') = 'object'
    AND (c.jsondata -> 'index' -> v_full_name) = 'true'::jsonb
  INTO v_indexed
  FROM postgresto.${config.table} c
  WHERE c.id = 'index';

  IF NOT COALESCE(v_indexed, false) THEN
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  END IF;

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

    IF pk_changed THEN
      SELECT CASE
        WHEN count(*) = 1 THEN max(to_jsonb(OLD) ->> column_name)
        ELSE string_agg(to_jsonb(OLD) ->> column_name, '|' ORDER BY ordinality)
      END
      INTO v_old_id
      FROM (
        SELECT attribute_def.attname AS column_name, key_def.ordinality
        FROM pg_index index_def
        JOIN unnest(index_def.indkey) WITH ORDINALITY
          AS key_def(attnum, ordinality) ON TRUE
        JOIN pg_attribute attribute_def
          ON attribute_def.attrelid = index_def.indrelid
          AND attribute_def.attnum = key_def.attnum
        WHERE index_def.indrelid = TG_RELID
          AND index_def.indisprimary
      ) primary_key;

      IF v_old_id IS NULL AND to_jsonb(OLD) ? 'id' THEN
        v_old_id := to_jsonb(OLD) ->> 'id';
      END IF;

      IF v_old_id IS NOT NULL AND btrim(v_old_id) <> '' THEN
        EXECUTE format(
          'DELETE FROM %s WHERE "table" = $1 AND id = $2',
          v_search_table
        )
        USING v_full_name, v_old_id;
      END IF;
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN
    v_row := to_jsonb(OLD);
  ELSE
    v_row := to_jsonb(NEW);
  END IF;

  SELECT CASE
    WHEN count(*) = 1 THEN max(v_row ->> column_name)
    ELSE string_agg(v_row ->> column_name, '|' ORDER BY ordinality)
  END
  INTO v_id
  FROM (
    SELECT attribute_def.attname AS column_name, key_def.ordinality
    FROM pg_index index_def
    JOIN unnest(index_def.indkey) WITH ORDINALITY
      AS key_def(attnum, ordinality) ON TRUE
    JOIN pg_attribute attribute_def
      ON attribute_def.attrelid = index_def.indrelid
      AND attribute_def.attnum = key_def.attnum
    WHERE index_def.indrelid = TG_RELID
      AND index_def.indisprimary
  ) primary_key;

  IF v_id IS NULL AND v_row ? 'id' THEN
    v_id := v_row ->> 'id';
  END IF;

  IF v_id IS NULL OR btrim(v_id) = '' THEN
    RAISE EXCEPTION 'table %.% requires a primary key (or id) for search indexing',
      TG_TABLE_SCHEMA, TG_TABLE_NAME;
  END IF;

  IF TG_OP = 'DELETE' THEN
    EXECUTE format(
      'DELETE FROM %s WHERE "table" = $1 AND id = $2',
      v_search_table
    )
    USING v_full_name, v_id;
  ELSE
    EXECUTE format(
      'INSERT INTO %s ("table", id, "index", indexed_at)
       VALUES ($1, $2, jsonb_to_tsvector(''russian'', $3::jsonb, ''["string", "numeric"]''), clock_timestamp())
       ON CONFLICT ("table", id) DO UPDATE SET
         "index" = EXCLUDED."index",
         indexed_at = EXCLUDED.indexed_at',
      v_search_table
    )
    USING v_full_name, v_id, v_row;
  END IF;

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$function$;
