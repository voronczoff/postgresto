--liquibase formatted sql
--changeset framework:seed-menu-2aa45772c0 runOnChange:true splitStatements:false
INSERT INTO postgresto.${menu.table}
  (id, jsondata)
VALUES (
  'pg_stat_statements_info',
  $json$
  {
    "view": "public.pg_stat_statements_info|Default",
    "label": "Pg Stat Statements Info",
    "parent": "system_tables",
    "priority": 7
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
