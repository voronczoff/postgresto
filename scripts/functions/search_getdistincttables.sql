--liquibase formatted sql
--changeset framework:search_getdistincttables runOnChange:true splitStatements:false logicalFilePath:search/cumulative_changelog.xml
-- DROP FUNCTION postgresto.search_getdistincttables(text, text, timestamptz, timestamptz);

DROP FUNCTION IF EXISTS postgresto.search_getdistincttables(text);
DROP FUNCTION IF EXISTS postgresto.search_getdistincttables(text, text, timestamptz, timestamptz);

CREATE OR REPLACE FUNCTION postgresto.search_getdistincttables(
    p_term text,
    p_schema text DEFAULT NULL,
    p_from timestamptz DEFAULT NULL,
    p_to timestamptz DEFAULT NULL
)
 RETURNS TABLE("table" text, hit_count bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT s."table", COUNT(*) as hit_count
    FROM search s,
         websearch_to_tsquery('russian', p_term) AS query
    WHERE s."index" @@ query
      AND (NULLIF(p_schema, '') IS NULL OR s."table" LIKE p_schema || '.%')
      AND (p_from IS NULL OR s.indexed_at >= p_from)
      AND (p_to IS NULL OR s.indexed_at <= p_to)
    GROUP BY s."table"
    ORDER BY hit_count DESC, s."table";
END;
$function$
;
