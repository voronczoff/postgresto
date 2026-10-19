--liquibase formatted sql
--changeset framework:seed-menu-demo runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'demo',
  $json$
  {
    "icon": "TableChart",
    "view": "postgresto.demo|Default",
    "label": "Demo",
    "parent": "lab",
    "priority": 0
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
