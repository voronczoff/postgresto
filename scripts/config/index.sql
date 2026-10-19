--liquibase formatted sql
--changeset framework:seed-config-1bc04b5291 runOnChange:true splitStatements:false
INSERT INTO postgresto.config
  (id, jsondata)
VALUES (
  'index',
  $json$
{
  "index": {
    "postgresto.config": true,
    "postgresto.demo": true,
    "postgresto.geo_countries": true,
    "postgresto.geo_regions": true,
    "postgresto.geo_subregions": true,
    "postgresto.menu": true,
    "postgresto.view": true,
    "public.databasechangelog": true,
    "public.databasechangeloglock": true,
    "public.pg_stat_statements": true,
    "public.pg_stat_statements_info": true
}
}  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;

SELECT * FROM postgresto.search_refresh();
