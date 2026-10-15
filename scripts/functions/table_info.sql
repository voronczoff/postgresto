--liquibase formatted sql
--changeset postgresto:fn-table_info runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
-- Table Info
-- SELECT postgresto.table_info('postgresto', 'demo');
DROP FUNCTION IF EXISTS postgresto.table_info(text, text);
CREATE OR REPLACE FUNCTION postgresto.table_info(
  p_schema text,
  p_table text
)
RETURNS TABLE (
  schema_name text,
  table_name text,
  size_total bigint,
  row_count bigint,
  size_data_index bigint,
  size_data bigint,
  size_index bigint,
  size_remains bigint
)
LANGUAGE sql
AS $function$
WITH table_sizes AS (
  SELECT
    schemaname AS schema_name,
    relname AS table_name,
    pg_total_relation_size(relid) AS size_total,
    pg_relation_size(relid) + pg_indexes_size(relid) AS size_data_index,
    pg_relation_size(relid) AS size_data,
    pg_indexes_size(relid) AS size_index,
    pg_total_relation_size(relid) - pg_relation_size(relid) - pg_indexes_size(relid) AS size_remains,
    (
      SELECT reltuples::bigint
      FROM pg_catalog.pg_class
      WHERE oid = relid
    ) AS row_count
  FROM pg_catalog.pg_statio_user_tables
  WHERE schemaname = p_schema
    AND relname = p_table
)
SELECT
  schema_name,
  table_name,
  size_total,
  row_count,
  size_data_index,
  size_data,
  size_index,
  size_remains
FROM table_sizes
UNION ALL
SELECT
  'TOTAL: ' || count(distinct schema_name)::text AS schema_name,
  'TOTAL: ' || count(table_name)::text AS table_name,
  SUM(size_total) AS size_total,
  SUM(row_count) AS row_count,
  SUM(size_data_index) AS size_data_index,
  SUM(size_data) AS size_data,
  SUM(size_index) AS size_index,
  SUM(size_remains) AS size_remains
FROM table_sizes
ORDER BY size_total DESC;
$function$;
