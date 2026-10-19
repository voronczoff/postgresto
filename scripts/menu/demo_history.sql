--liquibase formatted sql
--changeset framework:seed-menu-demo_history runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'demo_history',
  $json$
  {
    "icon": "History",
    "view": "postgresto.demo_history|Default",
    "label": "Demo History",
    "parent": "lab",
    "priority": 2
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
