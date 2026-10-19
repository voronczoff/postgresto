--liquibase formatted sql
--changeset postgresto:fn-database_info runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
DO $extension$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
EXCEPTION
  WHEN insufficient_privilege OR undefined_file OR feature_not_supported THEN
    NULL;
END;
$extension$;

DROP FUNCTION IF EXISTS postgresto.database_info_query_stats();
CREATE OR REPLACE FUNCTION postgresto.database_info_query_stats(p_limit integer DEFAULT 100)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  result jsonb;
BEGIN
  IF to_regclass('pg_stat_statements') IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  EXECUTE $query$
    SELECT coalesce(jsonb_agg(row_to_json(r) ORDER BY r.total_exec_time_sec DESC), '[]'::jsonb)
    FROM (
      SELECT
        pr.rolname,
        pd.datname,
        (pss.total_exec_time / 1000)::numeric AS total_exec_time_sec,
        (pss.mean_exec_time / 1000)::numeric AS mean_exec_time_sec,
        pss.calls,
        pss.rows,
        pss.shared_blks_hit,
        pss.shared_blks_read,
        pss.shared_blks_dirtied,
        pss.shared_blk_read_time AS blk_read_time,
        pss.shared_blk_write_time AS blk_write_time,
        pss.temp_blks_read,
        pss.temp_blks_written,
        pss.query
      FROM pg_stat_statements pss
      JOIN pg_database pd ON pss.dbid = pd.oid
      JOIN pg_roles pr ON pss.userid = pr.oid
      WHERE pss.query NOT ILIKE '%database_info%'
      ORDER BY total_exec_time_sec DESC
      LIMIT $1
    ) r
  $query$ INTO result USING greatest(coalesce(p_limit, 100), 1);

  RETURN coalesce(result, '[]'::jsonb);
EXCEPTION
  WHEN undefined_table OR undefined_column OR object_not_in_prerequisite_state THEN
    RETURN '[]'::jsonb;
END;
$function$;

REVOKE ALL ON FUNCTION postgresto.database_info_query_stats(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION postgresto.database_info_query_stats(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION postgresto.database_info_query_stats(integer) TO postgres;

DROP FUNCTION IF EXISTS postgresto.database_info_query_reports();
CREATE OR REPLACE FUNCTION postgresto.database_info_query_reports(p_limit integer DEFAULT 100)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  top_queries jsonb := '[]'::jsonb;
  worst_latency jsonb := '[]'::jsonb;
  heaviest_io jsonb := '[]'::jsonb;
  frequent_queries jsonb := '[]'::jsonb;
  worst_cache_hit jsonb := '[]'::jsonb;
  temp_file_usage jsonb := '[]'::jsonb;
BEGIN
  IF to_regclass('pg_stat_statements') IS NULL THEN
    RETURN jsonb_build_object(
      'top_queries', top_queries,
      'worst_latency', worst_latency,
      'heaviest_io', heaviest_io,
      'frequent_queries', frequent_queries,
      'worst_cache_hit', worst_cache_hit,
      'temp_file_usage', temp_file_usage
    );
  END IF;

  BEGIN
    EXECUTE $query$
      SELECT coalesce(jsonb_agg(row_to_json(r) ORDER BY r.total_ms DESC), '[]'::jsonb)
      FROM (
        SELECT
          queryid,
          calls,
          round(total_exec_time::numeric, 2) AS total_ms,
          round(mean_exec_time::numeric, 2) AS mean_ms,
          round(stddev_exec_time::numeric, 2) AS stddev_ms,
          rows,
          round((100 * total_exec_time / NULLIF(sum(total_exec_time) OVER (), 0))::numeric, 2) AS pct_total,
          round((100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0))::numeric, 2) AS hit_pct,
          query
        FROM pg_stat_statements
        WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
          AND query NOT LIKE '%pg_stat_statements%'
        ORDER BY total_exec_time DESC
        LIMIT $1
      ) r
    $query$ INTO top_queries USING greatest(coalesce(p_limit, 100), 1);

    EXECUTE $query$
      SELECT coalesce(jsonb_agg(row_to_json(r) ORDER BY r.mean_ms DESC), '[]'::jsonb)
      FROM (
        SELECT
          queryid,
          calls,
          round(mean_exec_time::numeric, 2) AS mean_ms,
          round(max_exec_time::numeric, 2) AS max_ms,
          round(total_exec_time::numeric, 2) AS total_ms,
          rows / GREATEST(calls, 1) AS rows_per_call,
          query
        FROM pg_stat_statements
        WHERE calls > 50
          AND query NOT LIKE '%pg_stat_statements%'
        ORDER BY mean_exec_time DESC
        LIMIT $1
      ) r
    $query$ INTO worst_latency USING greatest(coalesce(p_limit, 100), 1);

    EXECUTE $query$
      SELECT coalesce(jsonb_agg(row_to_json(r) ORDER BY r.total_disk DESC), '[]'::jsonb)
      FROM (
        SELECT
          queryid,
          calls,
          ((shared_blks_hit + shared_blks_dirtied) * 8192::bigint) AS total_cache,
          ((shared_blks_read + shared_blks_written + temp_blks_written) * 8192::bigint) AS total_disk,
          (shared_blks_read * 8192::bigint) AS read_from_disk,
          (shared_blks_hit * 8192::bigint) AS read_from_cache,
          (shared_blks_dirtied * 8192::bigint) AS write_to_cache,
          ((shared_blks_written + temp_blks_written) * 8192::bigint) AS write_to_disk,
          (temp_blks_written * 8192::bigint) AS temp_written,
          query
        FROM pg_stat_statements
        WHERE query NOT LIKE '%pg_stat_statements%'
        ORDER BY shared_blks_read + shared_blks_written + temp_blks_written DESC
        LIMIT $1
      ) r
    $query$ INTO heaviest_io USING greatest(coalesce(p_limit, 100), 1);

    EXECUTE $query$
      SELECT coalesce(jsonb_agg(row_to_json(r) ORDER BY r.calls DESC), '[]'::jsonb)
      FROM (
        SELECT
          queryid,
          calls,
          round(mean_exec_time::numeric, 2) AS mean_ms,
          round(total_exec_time::numeric, 2) AS total_ms,
          query
        FROM pg_stat_statements
        WHERE query NOT LIKE '%pg_stat_statements%'
        ORDER BY calls DESC
        LIMIT $1
      ) r
    $query$ INTO frequent_queries USING greatest(coalesce(p_limit, 100), 1);

    EXECUTE $query$
      SELECT coalesce(jsonb_agg(row_to_json(r) ORDER BY r.hit_pct ASC), '[]'::jsonb)
      FROM (
        SELECT
          queryid,
          calls,
          round((100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0))::numeric, 2) AS hit_pct,
          (shared_blks_read * 8192::bigint) AS read_from_disk,
          query
        FROM pg_stat_statements
        WHERE calls > 50
          AND shared_blks_hit + shared_blks_read > 0
          AND query NOT LIKE '%pg_stat_statements%'
        ORDER BY hit_pct ASC
        LIMIT $1
      ) r
    $query$ INTO worst_cache_hit USING greatest(coalesce(p_limit, 100), 1);

    EXECUTE $query$
      SELECT coalesce(jsonb_agg(row_to_json(r) ORDER BY r.temp_blks_written DESC), '[]'::jsonb)
      FROM (
        SELECT
          queryid,
          calls,
          (temp_blks_written * 8192::bigint) AS temp_written,
          (temp_blks_read * 8192::bigint) AS temp_read,
          round(mean_exec_time::numeric, 2) AS mean_ms,
          query
        FROM pg_stat_statements
        WHERE temp_blks_written > 0
          AND query NOT LIKE '%pg_stat_statements%'
        ORDER BY temp_blks_written DESC
        LIMIT $1
      ) r
    $query$ INTO temp_file_usage USING greatest(coalesce(p_limit, 100), 1);
  EXCEPTION
    WHEN undefined_table OR undefined_column OR object_not_in_prerequisite_state THEN
      NULL;
  END;

  RETURN jsonb_build_object(
    'top_queries', top_queries,
    'worst_latency', worst_latency,
    'heaviest_io', heaviest_io,
    'frequent_queries', frequent_queries,
    'worst_cache_hit', worst_cache_hit,
    'temp_file_usage', temp_file_usage
  );
END;
$function$;

REVOKE ALL ON FUNCTION postgresto.database_info_query_reports(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION postgresto.database_info_query_reports(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION postgresto.database_info_query_reports(integer) TO postgres;

DROP FUNCTION IF EXISTS postgresto.database_info();
-- Remove the legacy sectional overload so PostgREST resolves p_limit uniquely.
DROP FUNCTION IF EXISTS postgresto.database_info(text);
CREATE OR REPLACE FUNCTION postgresto.database_info(p_limit integer DEFAULT 100)
RETURNS jsonb
LANGUAGE sql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
WITH reports AS (
  SELECT postgresto.database_info_query_reports(p_limit) AS value
)
SELECT jsonb_build_object(
  'databases', (
    SELECT coalesce(jsonb_agg(row_to_json(rows) ORDER BY rows.size_bytes DESC), '[]'::jsonb)
    FROM (
      SELECT * FROM (
        WITH act AS (
          SELECT
            datid,
            count(*) AS connections,
            count(CASE WHEN state = 'active' THEN 1 END) AS active,
            count(CASE WHEN state = 'idle' THEN 1 END) AS idle,
            count(CASE WHEN state = 'idle in transaction' THEN 1 END) AS idle_in_tx,
            count(CASE WHEN wait_event_type = 'Lock' THEN 1 END) AS waiting_on_lock,
            max(CASE WHEN state = 'active' THEN now() - query_start END) AS longest_query,
            max(now() - xact_start) AS oldest_xact,
            string_agg(DISTINCT usename, ', ' ORDER BY usename) AS users,
            string_agg(DISTINCT nullif(application_name, ''), ', ' ORDER BY nullif(application_name, '')) AS apps
          FROM pg_catalog.pg_stat_activity
          WHERE datid IS NOT NULL
          GROUP BY datid
        ),
        base AS (
          SELECT
            d.datname AS database_name,
            pg_database_size(d.datname) AS size_bytes,
            coalesce(a.connections, 0) AS connections,
            coalesce(a.active, 0) AS active,
            coalesce(a.idle, 0) AS idle,
            coalesce(a.idle_in_tx, 0) AS idle_in_tx,
            coalesce(a.waiting_on_lock, 0) AS waiting_on_lock,
            a.longest_query,
            a.oldest_xact,
            coalesce(s.blks_hit, 0) AS blks_hit,
            coalesce(s.blks_read, 0) AS blks_read,
            coalesce(s.xact_commit, 0) AS xact_commit,
            coalesce(s.xact_rollback, 0) AS xact_rollback,
            coalesce(s.deadlocks, 0) AS deadlocks,
            coalesce(s.temp_files, 0) AS temp_files,
            coalesce(s.temp_bytes, 0) AS temp_bytes,
            coalesce(s.conflicts, 0) AS conflicts,
            age(d.datfrozenxid) AS xid_age,
            d.datconnlimit,
            coalesce(a.users, '') AS users,
            coalesce(a.apps, '') AS apps
          FROM pg_database d
          LEFT JOIN act a ON a.datid = d.oid
          LEFT JOIN pg_stat_database s ON s.datid = d.oid
        )
        SELECT
          database_name,
          size_bytes,
          users,
          connections,
          active,
          idle,
          idle_in_tx,
          deadlocks,
          longest_query,
          waiting_on_lock,
          oldest_xact,
          round(100.0 * blks_hit / nullif(blks_hit + blks_read, 0), 2) AS cache_hit_pct,
          xact_commit,
          xact_rollback,
          temp_files,
          pg_size_pretty(temp_bytes) AS temp_size,
          conflicts,
          xid_age,
          round(100.0 * xid_age / 2147483647, 2) AS wraparound_pct,
          datconnlimit,
          apps
        FROM base
        UNION ALL
        SELECT
          'TOTAL',
          sum(size_bytes),
          (SELECT coalesce(string_agg(DISTINCT usename, ', ' ORDER BY usename), '')
           FROM pg_catalog.pg_stat_activity
           WHERE datid IN (SELECT oid FROM pg_database)),
          sum(connections),
          sum(active),
          sum(idle),
          sum(idle_in_tx),
          sum(deadlocks),
          max(longest_query),
          sum(waiting_on_lock),
          max(oldest_xact),
          round(100.0 * sum(blks_hit) / nullif(sum(blks_hit + blks_read), 0), 2),
          sum(xact_commit),
          sum(xact_rollback),
          sum(temp_files),
          pg_size_pretty(sum(temp_bytes)::bigint),
          sum(conflicts),
          max(xid_age),
          round(100.0 * max(xid_age) / 2147483647, 2),
          NULL,
          (SELECT coalesce(string_agg(DISTINCT application_name, ', ' ORDER BY application_name), '')
           FROM pg_catalog.pg_stat_activity
           WHERE datid IN (SELECT oid FROM pg_database) AND application_name <> '')
        FROM base
      ) source_rows
      ORDER BY size_bytes DESC
      LIMIT greatest(coalesce(p_limit, 100), 1)
    ) rows
  ),
  'tables', (
    WITH table_sizes AS (
      SELECT
        t.schemaname AS schema_name,
        t.relname AS table_name,
        pg_total_relation_size(t.relid) AS size_total,
        c.reltuples::bigint AS row_count,
        pg_relation_size(t.relid) + pg_indexes_size(t.relid) AS size_data_index,
        pg_relation_size(t.relid) AS size_data,
        pg_indexes_size(t.relid) AS size_index,
        pg_total_relation_size(t.relid) - pg_relation_size(t.relid) - pg_indexes_size(t.relid) AS size_remains
      FROM pg_catalog.pg_statio_user_tables t
      LEFT JOIN pg_catalog.pg_class c ON c.oid = t.relid
    ), result_rows AS (
      SELECT * FROM table_sizes
      UNION ALL
      SELECT
        'TOTAL: ' || count(DISTINCT schema_name)::text,
        'TOTAL: ' || count(*)::text,
        sum(size_total),
        sum(row_count),
        sum(size_data_index),
        sum(size_data),
        sum(size_index),
        sum(size_remains)
      FROM table_sizes
      ORDER BY size_total DESC
      LIMIT greatest(coalesce(p_limit, 100), 1)
    )
    SELECT coalesce(jsonb_agg(row_to_json(result_rows) ORDER BY result_rows.size_total DESC), '[]'::jsonb)
    FROM result_rows
  ),
  'version', (SELECT jsonb_build_object('version', version())::jsonb),
  'dead_tuples', (
    SELECT coalesce(jsonb_agg(row_to_json(rows) ORDER BY rows.n_dead_tup DESC), '[]'::jsonb)
    FROM (
      SELECT * FROM (
        SELECT relname, n_live_tup, n_dead_tup
        FROM pg_stat_user_tables
        ORDER BY n_dead_tup DESC
      ) source_rows
      ORDER BY n_dead_tup DESC
      LIMIT greatest(coalesce(p_limit, 100), 1)
    ) rows
  ),
  'autovacuum', (
    SELECT coalesce(jsonb_agg(row_to_json(rows) ORDER BY rows.relname), '[]'::jsonb)
    FROM (
      SELECT * FROM (
        SELECT
          schemaname,
          relname,
          round(n_dead_tup::numeric / NULLIF(n_live_tup, 0) * 100) AS dead_pct,
          n_dead_tup,
          n_live_tup,
          autovacuum_count,
          last_vacuum,
          last_autovacuum,
          last_autoanalyze,
          last_analyze
        FROM pg_stat_all_tables
        WHERE n_live_tup > 0
      ) source_rows
      ORDER BY relname
      LIMIT greatest(coalesce(p_limit, 100), 1)
    ) rows
  ),
  'settings', (
    SELECT coalesce(jsonb_agg(row_to_json(rows) ORDER BY rows.name), '[]'::jsonb)
    FROM (
      SELECT * FROM (
        SELECT *
        FROM pg_settings
      ) source_rows
      ORDER BY name
      LIMIT greatest(coalesce(p_limit, 100), 1)
    ) rows
  ),
  'indexes', (
    SELECT coalesce(jsonb_agg(row_to_json(rows) ORDER BY rows.index_size DESC NULLS LAST), '[]'::jsonb)
    FROM (
      SELECT * FROM (
        WITH index_rows AS (
          SELECT
            i.relname AS index_name,
            pg_relation_size(i.oid) AS index_size,
            coalesce(s.idx_scan, 0) AS num_scans,
            n.nspname || '.' || t.relname AS table_name
          FROM pg_class t
          JOIN pg_index ix ON t.oid = ix.indrelid
          JOIN pg_class i ON i.oid = ix.indexrelid
          JOIN pg_namespace n ON n.oid = t.relnamespace
          LEFT JOIN pg_stat_user_indexes s ON s.indexrelid = i.oid
        )
        SELECT * FROM index_rows
        UNION ALL
        SELECT
          'TOTAL: ' || count(*)::text,
          sum(index_size),
          sum(num_scans),
          'TOTAL: ' || count(DISTINCT table_name)::text
        FROM index_rows
      ) source_rows
      ORDER BY index_size DESC NULLS LAST
      LIMIT greatest(coalesce(p_limit, 100), 1)
    ) rows
  ),
  'pg_stat_activity', (
    SELECT coalesce(jsonb_agg(row_to_json(rows) ORDER BY
      CASE
        WHEN rows.state = 'active' THEN 0
        WHEN rows.state = 'idle in transaction' THEN 1
        ELSE 2
      END,
      CASE
        WHEN rows.state = 'active' THEN rows.query_start
        WHEN rows.state = 'idle in transaction' THEN rows.xact_start
        ELSE NULL
      END ASC NULLS LAST,
      rows.query_start DESC NULLS LAST
    ), '[]'::jsonb)
    FROM (
      SELECT * FROM (
        SELECT
          state,
          CASE
            WHEN state = 'active' THEN now() - query_start              -- Time the current query has been running
            WHEN state = 'idle in transaction' THEN now() - xact_start  -- Time the open transaction has been held (possible lock/bloat risk)
            ELSE NULL                                                   -- Idle / other states: no meaningful duration
          END AS duration,  -- Computed: how long the backend has been busy or sitting in an open transaction
          query,                  -- Text of the most recent/current query (truncated to track_activity_query_size, default 1024 bytes)
          datname,                -- Name of the database this backend is connected to
          usename,                -- Name of the user (role) logged into this backend
          application_name,       -- Name set by the client app (e.g. via connection string or SET application_name)
          client_addr,            -- IP address of the connected client; NULL for Unix-socket connections or internal processes
          client_hostname,        -- Client hostname via reverse DNS lookup of client_addr; only populated if log_hostname is on
          client_port,            -- TCP port on the client side; -1 for Unix sockets
          backend_start,          -- When this backend process started (i.e. when the client connected)
          xact_start,             -- When the current transaction started; NULL if no transaction is open
          query_start,            -- When the current query started (or the last query started, if state is not 'active')
          state_change,           -- When the 'state' column last changed
          wait_event_type,        -- Category of what the backend is waiting on (Lock, LWLock, IO, Client, IPC, Timeout, etc.); NULL if not waiting
          wait_event,             -- Specific wait event name within that type (e.g. relation, transactionid, DataFileRead); NULL if not waiting
          query_id,               -- Internal hash identifying the query (PG 14+; requires compute_query_id enabled); joins to pg_stat_statements
          backend_type,           -- Kind of process: client backend, autovacuum worker, walsender, background writer, checkpointer, etc.
          pid,                    -- OS process ID of this backend; use with pg_cancel_backend(pid) / pg_terminate_backend(pid)
          datid,                  -- OID of the database this backend is connected to
          leader_pid,             -- PID of the parallel group leader if this is a parallel worker (PG 13+); NULL otherwise
          usesysid                -- OID of the user (role) logged into this backend
        FROM pg_stat_activity
        ORDER BY
          CASE                                                -- 1st sort key: bucket by state
            WHEN state = 'active' THEN 0                    -- Running queries first
            WHEN state = 'idle in transaction' THEN 1       -- Then open transactions doing nothing
            ELSE 2                                          -- Everything else (idle, etc.) last
          END,
          CASE                                                -- 2nd sort key: oldest first within each bucket
            WHEN state = 'active' THEN query_start          -- Active: longest-running at top
            WHEN state = 'idle in transaction' THEN xact_start  -- Idle in tx: longest-held at top
            ELSE NULL
          END ASC NULLS LAST,
          query_start DESC NULLS LAST                        -- 3rd sort key: most recent query first among the rest
      ) source_rows
      LIMIT greatest(coalesce(p_limit, 100), 1)
    ) rows
  ),
  'blocking_queries', (
    SELECT coalesce(jsonb_agg(row_to_json(rows) ORDER BY rows.started_at), '[]'::jsonb)
    FROM (
      SELECT * FROM (
        WITH blocked_processes AS (
          SELECT
            pid,
            unnest(pg_blocking_pids(pid)) AS blocked_by
          FROM pg_stat_activity
        ),
        blocking_queries AS (
          SELECT
            pid AS blocking_pid,
            query AS blocking_query,
            application_name AS blocking_application_name
          FROM pg_stat_activity
        )
        SELECT
          a.query_start AS started_at,
          now() - a.query_start AS duration,
          a.query,
          a.pid,
          a.usename,
          a.datname,
          a.state,
          a.application_name,
          blocking_queries.blocking_query AS blocked_by_query,
          blocking_queries.blocking_application_name AS blocked_by_application_name
        FROM pg_stat_activity a
        LEFT JOIN blocked_processes
          ON a.pid = blocked_processes.pid
        LEFT JOIN blocking_queries
          ON blocked_processes.blocked_by = blocking_queries.blocking_pid
        WHERE a.state = 'active'
        ORDER BY started_at
      ) source_rows
      ORDER BY started_at
      LIMIT greatest(coalesce(p_limit, 100), 1)
    ) rows
  ),
  'query_stats', postgresto.database_info_query_stats(p_limit),
  'top_queries', reports.value->'top_queries',
  'worst_latency', reports.value->'worst_latency',
  'heaviest_io', reports.value->'heaviest_io',
  'frequent_queries', reports.value->'frequent_queries',
  'worst_cache_hit', reports.value->'worst_cache_hit',
  'temp_file_usage', reports.value->'temp_file_usage',
  'replication', (
    SELECT coalesce(jsonb_agg(row_to_json(rows) ORDER BY rows.application_name), '[]'::jsonb)
    FROM (
      SELECT * FROM (
        SELECT
          pid,
          usename,
          application_name,
          client_addr,
          client_hostname,
          state,
          sync_state,
          sync_priority,
          sent_lsn,
          write_lsn,
          flush_lsn,
          replay_lsn,
          write_lag,
          flush_lag,
          replay_lag
        FROM pg_stat_replication
      ) source_rows
      ORDER BY application_name
      LIMIT greatest(coalesce(p_limit, 100), 1)
    ) rows
  )
)
FROM reports
;
$function$;
REVOKE ALL ON FUNCTION postgresto.database_info(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION postgresto.database_info(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION postgresto.database_info(integer) TO postgres;

CREATE OR REPLACE FUNCTION postgresto.database_info_reset_stats()
RETURNS void
LANGUAGE sql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $function$
  SELECT pg_stat_reset();
$function$;

REVOKE ALL ON FUNCTION postgresto.database_info_reset_stats() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION postgresto.database_info_reset_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION postgresto.database_info_reset_stats() TO postgres;

CREATE OR REPLACE FUNCTION postgresto.database_info_reset_query_stats()
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $function$
BEGIN
  IF to_regclass('public.pg_stat_statements') IS NULL THEN
    RAISE EXCEPTION 'pg_stat_statements is not installed';
  END IF;
  PERFORM public.pg_stat_statements_reset();
END;
$function$;

REVOKE ALL ON FUNCTION postgresto.database_info_reset_query_stats() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION postgresto.database_info_reset_query_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION postgresto.database_info_reset_query_stats() TO postgres;

-- execute grants for PostgREST RPC
