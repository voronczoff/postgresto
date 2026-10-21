--liquibase formatted sql
--changeset framework:seed-menu-menu-manager runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'menu_manager',
  $json$
  {
    "icon": "AccountTree",
    "view": "/pages/menu_manager",
    "label": "Menu Manager",
    "parent": "settings",
    "priority": 3,
    "description": "Organize sidebar sections and menu items."
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
