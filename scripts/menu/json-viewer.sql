--liquibase formatted sql
--changeset framework:seed-menu-json-viewer runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'json-viewer',
  $json$
  {
    "icon": "Visibility",
    "view": "/pages/json-viewer",
    "label": "JSON Viewer",
    "parent": "tools",
    "priority": 2
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
