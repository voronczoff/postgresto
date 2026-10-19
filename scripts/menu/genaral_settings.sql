--liquibase formatted sql
--changeset framework:seed-menu-29627d72de runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'genaral_settings',
  $json$
  {
    "icon": "ListAlt",
    "view": "/pages/general_settings?tab=brand",
    "label": "Genaral Settings",
    "parent": "settings",
    "priority": 0
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
