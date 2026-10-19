--liquibase formatted sql
--changeset framework:seed-menu-config runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'config',
  $json$
  {
    "icon": "Settings",
    "view": "postgresto.config|Default",
    "label": "Config",
    "parent": "system_tables",
    "priority": 0,
    "description": "conf"
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
