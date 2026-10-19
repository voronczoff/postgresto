--liquibase formatted sql
--changeset framework:seed-menu-1769396381 runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'authentication',
  $json$
  {
    "icon": "ListAlt",
    "view": "/pages/auth",
    "label": "Authentication",
    "parent": "settings",
    "priority": 1
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
