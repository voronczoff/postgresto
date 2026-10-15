--liquibase formatted sql
--changeset framework:seed-menu-4f8c124067 runOnChange:true splitStatements:false
INSERT INTO postgresto.${menu.table}
  (id, jsondata)
VALUES (
  'search_settings',
  $json$
  {
    "icon": "ListAlt",
    "view": "/pages/search_settings",
    "label": "Search Settings",
    "parent": "settings",
    "priority": 2
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
