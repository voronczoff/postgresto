--liquibase formatted sql
--changeset framework:search_refresh runOnChange:true splitStatements:false logicalFilePath:search/cumulative_changelog.xml
-- Combined search refresh: one table, one schema, or all schemas, backed by the
-- canonical postgresto.search table.
--
-- SELECT * FROM postgresto.search_refresh();                                  -- all schemas in search config / index
-- SELECT * FROM postgresto.search_refresh('postgresto');                     -- explicit schema, all tables
-- SELECT * FROM postgresto.search_refresh('postgresto', 'company');          -- one table, purge orphans
-- SELECT * FROM postgresto.search_refresh('postgresto', 'company', false);   -- skip orphan delete (faster)
-- SELECT * FROM postgresto.search_refresh('postgresto', 'company', purge_orphans => false);
--
-- Incremental when the source has updated_at; otherwise index new rows only.
-- Refreshes all tables in one transaction when processing a whole schema.
-- Logs deleted / added / updated counts per table (and dropped-table purge),
-- plus overall totals on schema-wide / top-level completion.
-- Unchanged tables (updated_at + matching row counts) skip the orphan anti-join.
--
-- Recommended indexes:
--   postgresto.${search.table} — idx_search_index_gin; search_table_indexed_at_idx
--   each source table — btree on (updated_at) when that column exists
--   each source table — primary key (or id fallback) (orphan deletes + upserts)

-- Remove the previous routine name when upgrading existing databases.
DROP ROUTINE IF EXISTS postgresto.refresh_search(text, text, boolean);
DROP ROUTINE IF EXISTS postgresto.refresh_search(text, text);
DROP ROUTINE IF EXISTS postgresto.refresh_search_all(text, boolean);

DROP ROUTINE IF EXISTS postgresto.search_refresh(text, text, boolean);
DROP ROUTINE IF EXISTS postgresto.search_refresh(text, text);
DROP ROUTINE IF EXISTS postgresto.search_refresh_all(text, boolean);

CREATE OR REPLACE FUNCTION postgresto.search_refresh(
  p_schema text DEFAULT NULL,
  p_table text DEFAULT NULL,
  purge_orphans boolean DEFAULT true
)
RETURNS TABLE("table" text, deleted int, added int, updated int, time_taken interval)
LANGUAGE plpgsql
AS $procedure$
DECLARE
  r record;
  r_drop record;
  v_schemas text[];
  v_schema_name text;
  v_tables text[];
  v_table_name text;
  v_current int := 0;
  v_full_name text;
  v_last_run timestamptz;
  v_now timestamptz;
  v_started timestamptz;
  v_phase timestamptz;
  v_call_ms numeric;
  v_elapsed interval;
  v_depth int;
  v_top_level boolean;
  v_has_updated_at boolean;
  v_pk_columns text[];
  v_id_expr text;
  v_id_match text;
  v_key_expr text;
  v_deleted int := 0;
  v_added int := 0;
  v_updated int := 0;
  v_total_deleted int := 0;
  v_total_added int := 0;
  v_total_updated int := 0;
  v_dropped_deleted int := 0;
  v_table_result text;
  v_time_taken interval;
  v_changed int;
  v_src_count int;
  v_search_count int;
  v_search_config jsonb;
  v_config_exists boolean;
BEGIN
  v_started := clock_timestamp();

  SELECT CASE
    WHEN jsonb_typeof(jsondata -> 'index') = 'object' THEN jsondata -> 'index'
    ELSE NULL
  END
  INTO v_search_config
  FROM postgresto.${config.table}
  WHERE id = 'index';

  v_config_exists := v_search_config IS NOT NULL;

  v_depth := coalesce(
    nullif(current_setting('postgresto.search_refresh.depth', true), '')::int,
    0
  );
  v_top_level := v_depth = 0;
  -- Session-level depth tracks nested table refreshes for logging.
  PERFORM set_config('postgresto.search_refresh.depth', (v_depth + 1)::text, false);

  IF v_top_level THEN
    -- cls: clear screen + scrollback before any output (ANSI; works in psql/terminal)
    RAISE NOTICE E'\033[2J\033[3J\033[H';
    RAISE NOTICE '[%] starting search ...',
      to_char(v_started, 'HH24:MI:SS');
    IF p_table IS NULL AND p_schema IS NULL THEN
      RAISE NOTICE '[%] all schemas (purge_orphans=%)',
        to_char(clock_timestamp(), 'HH24:MI:SS'),
        purge_orphans;
    ELSIF p_table IS NULL THEN
      RAISE NOTICE '[%] schema % (all tables, purge_orphans=%)',
        to_char(clock_timestamp(), 'HH24:MI:SS'),
        p_schema,
        purge_orphans;
    ELSE
      RAISE NOTICE '[%] table %.% (purge_orphans=%)',
        to_char(clock_timestamp(), 'HH24:MI:SS'),
        p_schema,
        p_table,
        purge_orphans;
    END IF;
  END IF;

  IF p_table IS NOT NULL AND p_schema IS NULL THEN
    RAISE EXCEPTION 'p_schema is required when refreshing a single table';
  END IF;

  --------------------------------------------------------------------------
  -- All schemas: refresh each schema present in search config and/or index
  --------------------------------------------------------------------------
  IF p_table IS NULL AND p_schema IS NULL THEN
    IF v_config_exists THEN
      SELECT coalesce(array_agg(x.schema_name ORDER BY x.schema_name), '{}')
      INTO v_schemas
      FROM (
        SELECT DISTINCT split_part(e.key, '.', 1) AS schema_name
        FROM jsonb_each(v_search_config) AS e(key, value)
        WHERE e.key LIKE '%.%'
          AND split_part(e.key, '.', 1) <> ''
        UNION
        SELECT DISTINCT split_part(s."table", '.', 1) AS schema_name
        FROM postgresto.${search.table} s
        WHERE s."table" LIKE '%.%'
          AND split_part(s."table", '.', 1) <> ''
      ) x;
    ELSE
      SELECT coalesce(array_agg(x.schema_name ORDER BY x.schema_name), ARRAY[current_schema()])
      INTO v_schemas
      FROM (
        SELECT DISTINCT split_part(s."table", '.', 1) AS schema_name
        FROM postgresto.${search.table} s
        WHERE s."table" LIKE '%.%'
          AND split_part(s."table", '.', 1) <> ''
      ) x;
    END IF;

    IF coalesce(array_length(v_schemas, 1), 0) = 0 THEN
      v_schemas := ARRAY[current_schema()];
    END IF;

    FOREACH v_schema_name IN ARRAY v_schemas
    LOOP
      v_phase := clock_timestamp();
      BEGIN
        FOR r IN
          SELECT f."table", f.deleted, f.added, f.updated, f.time_taken
          FROM postgresto.search_refresh(v_schema_name, NULL, purge_orphans) f
        LOOP
          IF r."table" = 'TOTAL' THEN
            v_total_deleted := v_total_deleted + coalesce(r.deleted, 0);
            v_total_added := v_total_added + coalesce(r.added, 0);
            v_total_updated := v_total_updated + coalesce(r.updated, 0);
          ELSE
            "table" := r."table";
            deleted := r.deleted;
            added := r.added;
            updated := r.updated;
            time_taken := r.time_taken;
            RETURN NEXT;
          END IF;
        END LOOP;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '[%] search_refresh failed for schema %: %',
          to_char(clock_timestamp(), 'HH24:MI:SS'),
          v_schema_name,
          SQLERRM;
      END;
      v_call_ms := round(extract(epoch from (clock_timestamp() - v_phase))::numeric * 1000, 1);
      RAISE NOTICE '[%] schema % finished — call: % ms',
        to_char(clock_timestamp(), 'HH24:MI:SS'),
        v_schema_name,
        v_call_ms;
    END LOOP;

    v_elapsed := clock_timestamp() - v_started;

    RAISE NOTICE '[%] done — % schemas processed — deleted: %, added: %, updated: % — time taken: %',
      to_char(clock_timestamp(), 'HH24:MI:SS'),
      coalesce(array_length(v_schemas, 1), 0),
      v_total_deleted,
      v_total_added,
      v_total_updated,
      (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');

    RAISE NOTICE '[%] end search — deleted: %, added: %, updated: % — time taken: %',
      to_char(clock_timestamp(), 'HH24:MI:SS'),
      v_total_deleted,
      v_total_added,
      v_total_updated,
      (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');

    PERFORM set_config('postgresto.search_refresh.depth', v_depth::text, false);
    "table" := 'TOTAL';
    deleted := v_total_deleted;
    added := v_total_added;
    updated := v_total_updated;
    time_taken := v_elapsed;
    RETURN NEXT;
    RETURN;
  END IF;

  --------------------------------------------------------------------------
  -- Schema-wide: prune dropped tables, then refresh each
  --------------------------------------------------------------------------
  IF p_table IS NULL THEN
    IF purge_orphans THEN
      FOR r_drop IN
        SELECT
          s."table" AS full_table_name,
          count(*)::int AS deleted_rows
        FROM postgresto.${search.table} s
        WHERE s."table" LIKE p_schema || '.%'
          AND NOT EXISTS (
            SELECT 1
            FROM information_schema.tables t
            WHERE t.table_schema = p_schema
              AND t.table_type = 'BASE TABLE'
              AND p_schema || '.' || t.table_name = s."table"
          )
        GROUP BY s."table"
        ORDER BY s."table"
      LOOP
        RAISE NOTICE '[%] dropped table % — deleting % search rows',
          to_char(clock_timestamp(), 'HH24:MI:SS'),
          r_drop.full_table_name,
          r_drop.deleted_rows;
      END LOOP;

      DELETE FROM postgresto.${search.table} s
      WHERE s."table" LIKE p_schema || '.%'
        AND NOT EXISTS (
          SELECT 1
          FROM information_schema.tables t
          WHERE t.table_schema = p_schema
            AND t.table_type = 'BASE TABLE'
            AND p_schema || '.' || t.table_name = s."table"
        );

      GET DIAGNOSTICS v_dropped_deleted = ROW_COUNT;

      IF v_dropped_deleted > 0 THEN
        v_total_deleted := v_total_deleted + v_dropped_deleted;
        RAISE NOTICE '[%] removed % search rows for dropped tables in schema %',
          to_char(clock_timestamp(), 'HH24:MI:SS'),
          v_dropped_deleted,
          p_schema;
      END IF;
    END IF;

    IF v_config_exists AND purge_orphans THEN
      DELETE FROM postgresto.${search.table} s
      WHERE s."table" LIKE p_schema || '.%'
        AND (
          NOT jsonb_exists(v_search_config, s."table")
          OR (v_search_config -> s."table") = 'false'::jsonb
        );

      GET DIAGNOSTICS v_dropped_deleted = ROW_COUNT;

      IF v_dropped_deleted > 0 THEN
        v_total_deleted := v_total_deleted + v_dropped_deleted;
        RAISE NOTICE '[%] removed % search rows for disabled or unlisted tables in schema %',
          to_char(clock_timestamp(), 'HH24:MI:SS'),
          v_dropped_deleted,
          p_schema;
      END IF;
    END IF;

    -- Materialize names first to avoid re-scanning catalogs.
    IF v_config_exists THEN
      SELECT coalesce(array_agg(x.table_name ORDER BY x.table_name), '{}')
      INTO v_tables
      FROM (
        SELECT split_part(e.key, '.', 2) AS table_name
        FROM jsonb_each(v_search_config) AS e(key, value)
        WHERE e.key LIKE p_schema || '.%'
          AND e.value = 'true'::jsonb
          AND split_part(e.key, '.', 2) NOT LIKE '%\_history'
          AND split_part(e.key, '.', 2) NOT LIKE '%\_events'
          AND split_part(e.key, '.', 2) NOT LIKE '%\_raw'
          AND split_part(e.key, '.', 2) <> '${search.table}'
          AND EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = p_schema
              AND c.relname = split_part(e.key, '.', 2)
              AND c.relkind IN ('r', 'v')
          )
      ) x;
    ELSE
      SELECT coalesce(array_agg(x.table_name ORDER BY x.table_name), '{}')
      INTO v_tables
      FROM (
        SELECT c.relname AS table_name
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = p_schema
          AND c.relkind IN ('r', 'v')
          AND c.relname NOT LIKE '%\_history'
          AND c.relname NOT LIKE '%\_events'
          AND c.relname NOT LIKE '%\_raw'
          AND c.relname <> '${search.table}'
      ) x;
    END IF;

    FOREACH v_table_name IN ARRAY v_tables
    LOOP
      v_current := v_current + 1;

      PERFORM set_config('postgresto.search_refresh.last_updated_at', '-', false);

      v_phase := clock_timestamp();
      BEGIN
        SELECT f."table", f.deleted, f.added, f.updated, f.time_taken
        INTO v_table_result, v_deleted, v_added, v_updated, v_time_taken
        FROM postgresto.search_refresh(p_schema, v_table_name, purge_orphans) f;
      EXCEPTION WHEN OTHERS THEN
        v_table_result := p_schema || '.' || v_table_name;
        v_deleted := 0;
        v_added := 0;
        v_updated := 0;
        v_time_taken := clock_timestamp() - v_phase;
        RAISE WARNING '[%] search_refresh failed for %.%: %',
          to_char(clock_timestamp(), 'HH24:MI:SS'),
          p_schema,
          v_table_name,
          SQLERRM;
      END;
      v_call_ms := round(extract(epoch from (clock_timestamp() - v_phase))::numeric * 1000, 1);

      v_total_deleted := v_total_deleted + v_deleted;
      v_total_added := v_total_added + v_added;
      v_total_updated := v_total_updated + v_updated;

      RAISE NOTICE '[%] %/% %.% — deleted: %, added: %, updated: % — updated_at: % — call: % ms',
        to_char(clock_timestamp(), 'HH24:MI:SS'),
        v_current,
        coalesce(array_length(v_tables, 1), 0),
        p_schema,
        v_table_name,
        v_deleted,
        v_added,
        v_updated,
        coalesce(nullif(current_setting('postgresto.search_refresh.last_updated_at', true), ''), '-'),
        v_call_ms;

      "table" := v_table_result;
      deleted := v_deleted;
      added := v_added;
      updated := v_updated;
      time_taken := v_time_taken;
      RETURN NEXT;
    END LOOP;

    v_elapsed := clock_timestamp() - v_started;

    RAISE NOTICE '[%] done — % tables processed in schema % — deleted: %, added: %, updated: % — time taken: %',
      to_char(clock_timestamp(), 'HH24:MI:SS'),
      v_current,
      p_schema,
      v_total_deleted,
      v_total_added,
      v_total_updated,
      (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');

    RAISE NOTICE '[%] end search — deleted: %, added: %, updated: % — time taken: %',
      to_char(clock_timestamp(), 'HH24:MI:SS'),
      v_total_deleted,
      v_total_added,
      v_total_updated,
      (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');

    PERFORM set_config('postgresto.search_refresh.depth', v_depth::text, false);
    "table" := 'TOTAL';
    deleted := v_total_deleted;
    added := v_total_added;
    updated := v_total_updated;
    time_taken := v_elapsed;
    RETURN NEXT;
    RETURN;
  END IF;

  --------------------------------------------------------------------------
  -- Single table
  --------------------------------------------------------------------------
  IF p_table = '${search.table}' THEN
    IF v_top_level THEN
      RAISE NOTICE '[%] skip %.% — search index table is not indexed',
        to_char(clock_timestamp(), 'HH24:MI:SS'),
        p_schema,
        '${search.table}';
    END IF;
    "table" := p_schema || '.' || '${search.table}';
    deleted := 0;
    added := 0;
    updated := 0;
    time_taken := clock_timestamp() - v_started;
    PERFORM set_config('postgresto.search_refresh.depth', v_depth::text, false);
    RETURN NEXT;
    RETURN;
  END IF;

  v_full_name := p_schema || '.' || p_table;

  IF v_config_exists AND (
    NOT jsonb_exists(v_search_config, v_full_name)
    OR (v_search_config -> v_full_name) = 'false'::jsonb
  ) THEN
    IF purge_orphans THEN
      DELETE FROM postgresto.${search.table} s WHERE s."table" = v_full_name;
      GET DIAGNOSTICS v_deleted = ROW_COUNT;
    END IF;

    v_elapsed := clock_timestamp() - v_started;
    IF v_top_level THEN
      RAISE NOTICE '[%] skip %.% — disabled in search config — deleted % search rows — time taken: %',
        to_char(clock_timestamp(), 'HH24:MI:SS'),
        p_schema,
        p_table,
        v_deleted,
        (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');
    END IF;

    "table" := v_full_name;
    deleted := v_deleted;
    added := 0;
    updated := 0;
    time_taken := v_elapsed;
    PERFORM set_config('postgresto.search_refresh.depth', v_depth::text, false);
    RETURN NEXT;
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables t
    WHERE t.table_schema = p_schema
      AND t.table_name = p_table
      AND t.table_type IN ('BASE TABLE', 'VIEW')
  ) THEN
    IF purge_orphans THEN
      DELETE FROM postgresto.${search.table} s WHERE s."table" = v_full_name;
      GET DIAGNOSTICS v_deleted = ROW_COUNT;
    END IF;

    v_elapsed := clock_timestamp() - v_started;
    IF v_top_level THEN
      RAISE NOTICE '[%] %.% — table missing, deleted % search rows — time taken: %',
        to_char(clock_timestamp(), 'HH24:MI:SS'),
        p_schema,
        p_table,
        v_deleted,
        (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');

      RAISE NOTICE '[%] end search — deleted: %, added: 0, updated: 0 — time taken: %',
        to_char(clock_timestamp(), 'HH24:MI:SS'),
        v_deleted,
        (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');
    END IF;

    "table" := v_full_name;
    deleted := v_deleted;
    added := 0;
    updated := 0;
    time_taken := v_elapsed;
    PERFORM set_config('postgresto.search_refresh.depth', v_depth::text, false);
    RETURN NEXT;
    RETURN;
  END IF;

  -- Use the primary key as the stable search id. Search ids are always text:
  -- scalar keys (including integers) are cast to text, while composite keys
  -- are joined as key1|key2|... in primary-key column order.
  SELECT array_agg(kcu.column_name ORDER BY kcu.ordinal_position)
  INTO v_pk_columns
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON kcu.constraint_schema = tc.constraint_schema
   AND kcu.constraint_name = tc.constraint_name
   AND kcu.table_schema = tc.table_schema
   AND kcu.table_name = tc.table_name
  WHERE tc.constraint_type = 'PRIMARY KEY'
    AND tc.table_schema = p_schema
    AND tc.table_name = p_table;

  -- Keep compatibility with existing tables that expose id without a
  -- declared primary key.
  IF v_pk_columns IS NULL THEN
    IF EXISTS (
      SELECT 1
      FROM information_schema.columns c
      WHERE c.table_schema = p_schema
        AND c.table_name = p_table
        AND c.column_name = 'id'
    ) THEN
      v_pk_columns := ARRAY['id'];
    ELSE
      RAISE EXCEPTION 'table %.% has no primary key or id column', p_schema, p_table;
    END IF;
  END IF;

  SELECT string_agg(format('src.%I::text', key_column), ', ' ORDER BY ordinality)
  INTO v_key_expr
  FROM unnest(v_pk_columns) WITH ORDINALITY AS key_columns(key_column, ordinality);

  v_id_expr := format('concat_ws(''|'', %s)', v_key_expr);
  v_id_match := format('%s = s.id', v_id_expr);

  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns c
    WHERE c.table_schema = p_schema
      AND c.table_name = p_table
      AND c.column_name = 'updated_at'
  ) INTO v_has_updated_at;

  SELECT MAX(s.indexed_at)
  INTO v_last_run
  FROM postgresto.${search.table} s
  WHERE s."table" = v_full_name;

  PERFORM set_config(
    'postgresto.search_refresh.last_updated_at',
    CASE
      WHEN NOT v_has_updated_at THEN 'no'
      WHEN v_last_run IS NULL THEN 'first'
      ELSE to_char(v_last_run, 'HH24:MI:SS')
    END,
    false
  );

  v_now := clock_timestamp();

  --------------------------------------------------------------------------
  -- Incremental fast path: when nothing changed, skip the expensive orphan
  -- anti-join (that was ~seconds per table even with 0/0/0).
  -- Safe when every insert/update bumps updated_at (normal for these docs).
  --------------------------------------------------------------------------
  IF v_has_updated_at AND v_last_run IS NOT NULL THEN
    EXECUTE format(
      $q$ SELECT count(*)::int FROM %I.%I src WHERE src.updated_at > %L::timestamptz $q$,
      p_schema, p_table, v_last_run
    ) INTO v_changed;

    EXECUTE format(
      $q$ SELECT count(*)::int FROM %I.%I $q$,
      p_schema, p_table
    ) INTO v_src_count;

    SELECT count(*)::int
    INTO v_search_count
    FROM postgresto.${search.table} s
    WHERE s."table" = v_full_name;

    IF v_changed = 0 AND v_search_count = v_src_count THEN
      v_elapsed := clock_timestamp() - v_started;
      IF v_top_level THEN
        RAISE NOTICE '[%] %.% — deleted: 0, added: 0, updated: 0 — unchanged — time taken: %',
          to_char(clock_timestamp(), 'HH24:MI:SS'),
          p_schema,
          p_table,
          (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');

        RAISE NOTICE '[%] end search — deleted: 0, added: 0, updated: 0 — time taken: %',
          to_char(clock_timestamp(), 'HH24:MI:SS'),
          (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');
      END IF;

      "table" := v_full_name;
      deleted := 0;
      added := 0;
      updated := 0;
      time_taken := v_elapsed;
      PERFORM set_config('postgresto.search_refresh.depth', v_depth::text, false);
      RETURN NEXT;
      RETURN;
    END IF;

    -- Deletes only: purge orphans, skip empty upsert
    IF v_changed = 0 AND purge_orphans AND v_search_count > v_src_count THEN
      EXECUTE format($q$
        DELETE FROM postgresto.${search.table} s
        WHERE s."table" = %L
          AND NOT EXISTS (
            SELECT 1 FROM %I.%I src WHERE %s
          )
      $q$, v_full_name, p_schema, p_table, v_id_match);

      GET DIAGNOSTICS v_deleted = ROW_COUNT;

      v_elapsed := clock_timestamp() - v_started;
      IF v_top_level THEN
        RAISE NOTICE '[%] %.% — deleted: %, added: 0, updated: 0 — time taken: %',
          to_char(clock_timestamp(), 'HH24:MI:SS'),
          p_schema,
          p_table,
          v_deleted,
          (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');

        RAISE NOTICE '[%] end search — deleted: %, added: 0, updated: 0 — time taken: %',
          to_char(clock_timestamp(), 'HH24:MI:SS'),
          v_deleted,
          (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');
      END IF;

      "table" := v_full_name;
      deleted := v_deleted;
      added := 0;
      updated := 0;
      time_taken := v_elapsed;
      PERFORM set_config('postgresto.search_refresh.depth', v_depth::text, false);
      RETURN NEXT;
      RETURN;
    END IF;
  END IF;

  -- Orphan purge only when the index has more rows than the source.
  -- Avoids the expensive anti-join when counts already match.
  IF purge_orphans THEN
    IF v_src_count IS NULL OR v_search_count IS NULL THEN
      EXECUTE format(
        $q$ SELECT count(*)::int FROM %I.%I $q$,
        p_schema, p_table
      ) INTO v_src_count;

      SELECT count(*)::int
      INTO v_search_count
      FROM postgresto.${search.table} s
      WHERE s."table" = v_full_name;
    END IF;

    IF v_search_count > v_src_count THEN
      EXECUTE format($q$
        DELETE FROM postgresto.${search.table} s
        WHERE s."table" = %L
          AND NOT EXISTS (
            SELECT 1 FROM %I.%I src WHERE %s
          )
      $q$, v_full_name, p_schema, p_table, v_id_match);

      GET DIAGNOSTICS v_deleted = ROW_COUNT;
    END IF;
  END IF;

  -- upsert: incremental if updated_at exists, else insert new rows only.
  -- Without updated_at there is no reliable way to detect changes to an
  -- existing row, so reindexing it on every refresh is intentionally avoided.
  IF v_has_updated_at THEN
    IF v_changed IS NOT NULL AND v_changed = 0 AND v_last_run IS NOT NULL THEN
      -- No source rows newer than last index; only missing rows (search < source)
      EXECUTE format($q$
        WITH upsert AS (
          INSERT INTO postgresto.${search.table} ("table", id, "index", indexed_at)
          SELECT
            %L,
            %s,
            jsonb_to_tsvector(
              'russian',
              to_jsonb(src),
              '["string", "numeric"]'
            ),
            %L::timestamptz
          FROM %I.%I src
          WHERE NOT EXISTS (
            SELECT 1 FROM postgresto.${search.table} s
            WHERE s."table" = %L AND %s
          )
          ON CONFLICT ("table", id) DO UPDATE SET
            "index" = EXCLUDED."index",
            indexed_at = EXCLUDED.indexed_at
          RETURNING (xmax = 0) AS is_insert
        )
        SELECT
          count(*) FILTER (WHERE is_insert)::int,
          count(*) FILTER (WHERE NOT is_insert)::int
        FROM upsert
      $q$, v_full_name, v_id_expr, v_now, p_schema, p_table, v_full_name, v_id_match)
      INTO v_added, v_updated;
    ELSE
      EXECUTE format($q$
        WITH upsert AS (
          INSERT INTO postgresto.${search.table} ("table", id, "index", indexed_at)
          SELECT
            %L,
            %s,
            jsonb_to_tsvector(
              'russian',
              to_jsonb(src),
              '["string", "numeric"]'
            ),
            %L::timestamptz
          FROM %I.%I src
          WHERE %L::timestamptz IS NULL
             OR src.updated_at > %L::timestamptz
          ON CONFLICT ("table", id) DO UPDATE SET
            "index" = EXCLUDED."index",
            indexed_at = EXCLUDED.indexed_at
          RETURNING (xmax = 0) AS is_insert
        )
        SELECT
          count(*) FILTER (WHERE is_insert)::int,
          count(*) FILTER (WHERE NOT is_insert)::int
        FROM upsert
      $q$, v_full_name, v_id_expr, v_now, p_schema, p_table, v_last_run, v_last_run)
      INTO v_added, v_updated;
    END IF;
  ELSE
    EXECUTE format($q$
      WITH upsert AS (
        INSERT INTO postgresto.${search.table} ("table", id, "index", indexed_at)
        SELECT
          %L,
          %s,
          jsonb_to_tsvector(
            'russian',
            to_jsonb(src),
            '["string", "numeric"]'
          ),
          %L::timestamptz
        FROM %I.%I src
        ON CONFLICT ("table", id) DO NOTHING
        RETURNING true AS is_insert
      )
      SELECT
        count(*) FILTER (WHERE is_insert)::int,
        count(*) FILTER (WHERE NOT is_insert)::int
      FROM upsert
    $q$, v_full_name, v_id_expr, v_now, p_schema, p_table)
    INTO v_added, v_updated;
  END IF;

  v_elapsed := clock_timestamp() - v_started;
  IF v_top_level THEN
    RAISE NOTICE '[%] %.% — deleted: %, added: %, updated: % — time taken: %',
      to_char(clock_timestamp(), 'HH24:MI:SS'),
      p_schema,
      p_table,
      v_deleted,
      v_added,
      v_updated,
      (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');

    RAISE NOTICE '[%] end search — deleted: %, added: %, updated: % — time taken: %',
      to_char(clock_timestamp(), 'HH24:MI:SS'),
      v_deleted,
      v_added,
      v_updated,
      (round(extract(epoch from v_elapsed)::numeric, 1)::text || 's');
  END IF;

  "table" := v_full_name;
  deleted := v_deleted;
  added := v_added;
  updated := v_updated;
  time_taken := v_elapsed;
  PERFORM set_config('postgresto.search_refresh.depth', v_depth::text, false);
  RETURN NEXT;
END;
$procedure$;
