--liquibase formatted sql
--changeset framework:seed-menu-f5dcbde445 runOnChange:true splitStatements:false
INSERT INTO postgresto.${menu.table}
  (id, jsondata)
VALUES (
  'databasechangeloglock',
  $json$
  {
    "view": "public.databasechangeloglock|Default",
    "label": "Databasechangeloglock",
    "parent": "system_tables",
    "priority": 5
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
