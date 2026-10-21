--liquibase formatted sql
--changeset framework:seed-menu-3953f9ddf9 runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'lab',
  $json$
  {
    "icon": "Science",
    "label": "LAB",
    "priority": 3
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
