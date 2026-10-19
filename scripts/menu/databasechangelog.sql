--liquibase formatted sql
--changeset framework:seed-menu-857d6603bd runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'databasechangelog',
  $json$
  {
    "icon": "ListAlt",
    "view": "public.databasechangelog|Default",
    "label": "Databasechangelog",
    "parent": "system_tables",
    "priority": 4
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
