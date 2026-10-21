--liquibase formatted sql
--changeset framework:seed-menu-view-configurator runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'view_configurator',
  $json$
  {
    "icon": "TableChart",
    "view": "/pages/view_configurator",
    "label": "View Configurator",
    "parent": "settings",
    "priority": 4,
    "description": "Create and manage table views from your PostgREST schema."
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
