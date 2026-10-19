--liquibase formatted sql
--changeset framework:seed-menu-demo_tree runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'demo_tree',
  $json$
  {
    "icon": "AccountTree",
    "view": "postgresto.demo|Recursive Tree",
    "label": "Demo Tree",
    "parent": "lab",
    "priority": 1
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
