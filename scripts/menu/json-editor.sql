--liquibase formatted sql
--changeset framework:seed-menu-1480fc440e runOnChange:true splitStatements:false
INSERT INTO postgresto.${menu.table}
  (id, jsondata)
VALUES (
  'json-editor',
  $json$
  {
    "icon": "DataObject",
    "view": "/pages/json-editor",
    "label": "JSON Editor",
    "parent": "tools",
    "priority": 1
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
