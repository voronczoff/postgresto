--liquibase formatted sql
--changeset framework:seed-menu-search runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'search',
  $json$
  {
    "icon": "Search",
    "view": "postgresto.search|Default",
    "label": "Search",
    "parent": "system_tables",
    "priority": 3,
    "description": "qwe"
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
