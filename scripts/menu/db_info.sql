--liquibase formatted sql
--changeset framework:seed-menu-074b9a3b73 runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'db_info',
  $json$
  {
    "icon": "InfoOutlined",
    "view": "/pages/server_info",
    "label": "Server Info",
    "parent": "settings",
    "priority": 5,
    "description": "Inspect PostgreSQL storage, activity, indexes, and settings."
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
