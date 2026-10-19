--liquibase formatted sql
--changeset framework:seed-menu-tools runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'tools',
  $json$
  {
    "icon": "Construction",
    "label": "TOOLS",
    "priority": 4
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
