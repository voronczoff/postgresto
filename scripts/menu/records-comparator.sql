--liquibase formatted sql
--changeset framework:seed-menu-records-comparator runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'records-comparator',
  $json$
  {
    "icon": "Difference",
    "view": "/pages/records-comparator",
    "label": "Records Comparator",
    "parent": "tools",
    "priority": 4
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
