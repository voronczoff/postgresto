--liquibase formatted sql
--changeset framework:seed-view-55f962e263 runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'public.pg_stat_statements_info|Default',
  $json$
  {
    "table": "pg_stat_statements_info",
    "schema": "public",
    "columns": {
      "dealloc": {
        "path": "dealloc",
        "type": "number",
        "orderList": 1,
        "searchable": false
      },
      "stats_reset": {
        "path": "stats_reset",
        "type": "datetime",
        "orderList": 2
      }
    },
    "sorting": [],
    "rowcount": true,
    "selector": true
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
