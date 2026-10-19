--liquibase formatted sql
--changeset framework:seed-menu-settings runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'settings',
  $json$
  {
    "icon": "Settings",
    "view": "/settings",
    "label": "SETTINGS",
    "priority": 6
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
