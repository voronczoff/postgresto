--liquibase formatted sql
--changeset framework:seed-menu-json-comparator runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'json-comparator',
  $json$
  {
    "icon": "CompareArrows",
    "view": "/pages/json-comparator",
    "label": "JSON Comparator",
    "parent": "tools",
    "priority": 3
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
