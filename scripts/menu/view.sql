--liquibase formatted sql
--changeset framework:seed-menu-view runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'view',
  $json$
  {
    "icon": "Layers",
    "view": "postgresto.view|plain",
    "label": "View",
    "parent": "system_tables",
    "priority": 2,
    "description": "123"
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
