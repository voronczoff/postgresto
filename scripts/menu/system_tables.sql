--liquibase formatted sql
--changeset framework:seed-menu-64bbb138c3 runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'system_tables',
  $json$
  {
    "icon": "ListAlt",
    "label": "System Tables",
    "parent": "settings",
    "priority": 3
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
