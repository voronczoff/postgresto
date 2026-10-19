--liquibase formatted sql
--changeset framework:seed-menu-decoder runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'decoder',
  $json$
  {
    "icon": "Transform",
    "view": "/pages/decoder",
    "label": "Decoder",
    "parent": "tools",
    "priority": 0
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
