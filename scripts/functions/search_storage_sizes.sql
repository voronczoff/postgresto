--liquibase formatted sql
--changeset postgresto:fn-search_storage_sizes runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
-- Per-source search row bytes and source table storage, without table indexes.
-- SECURITY INVOKER preserves the caller's search-table permissions and RLS.
CREATE OR REPLACE FUNCTION postgresto.search_storage_sizes(p_tables text[])
RETURNS TABLE (table_key text, search_size bigint, table_size bigint)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog
AS $function$
  WITH requested AS (
    SELECT DISTINCT unnest(p_tables) AS table_key
  ), search_sizes AS (
    -- Row sizes exclude indexes and shared page overhead. They are not an
    -- allocation of the entire physical search relation to individual sources.
    SELECT s."table" AS table_key, sum(pg_column_size(s))::bigint AS bytes
    FROM postgresto.search s
    JOIN requested r ON r.table_key = s."table"
    GROUP BY s."table"
  )
  SELECT r.table_key,
         coalesce(s.bytes, 0)::bigint,
         CASE WHEN c.relkind IN ('r', 'm', 'p')
                   AND has_table_privilege(c.oid, 'SELECT')
              THEN CASE WHEN c.relkind = 'p'
                        THEN (SELECT coalesce(sum(pg_table_size(p.relid)), 0)::bigint
                              FROM pg_partition_tree(c.oid) p WHERE p.isleaf)
                        ELSE pg_table_size(c.oid)
                   END
              ELSE NULL
         END AS table_size
  FROM requested r
  LEFT JOIN search_sizes s ON s.table_key = r.table_key
  LEFT JOIN (pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace)
    ON n.nspname || '.' || c.relname = r.table_key;
$function$;

NOTIFY pgrst, 'reload schema';
