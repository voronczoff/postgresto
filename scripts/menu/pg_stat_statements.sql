--liquibase formatted sql
--changeset framework:seed-menu-c182f3e761 runOnChange:true splitStatements:false
INSERT INTO postgresto.${menu.table}
  (id, jsondata)
VALUES (
  'pg_stat_statements',
  $json$
  {
    "view": "public.pg_stat_statements|Default",
    "label": "Pg Stat Statements",
    "parent": "system_tables",
    "priority": 6
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
