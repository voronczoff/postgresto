--liquibase formatted sql
--changeset framework:seed-menu-menu runOnChange:true splitStatements:false
INSERT INTO postgresto.${menu.table}
  (id, jsondata)
VALUES (
  'menu',
  $json$
  {
    "icon": "MenuBook",
    "view": "postgresto.menu|tree",
    "label": "Menu",
    "parent": "system_tables",
    "priority": 1,
    "description": "Menu tree"
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
