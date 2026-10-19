--liquibase formatted sql
--changeset framework:seed-menu-globalsearch runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'globalsearch',
  $json$
  {
    "icon": "TravelExplore",
    "view": "/globalsearch",
    "label": "GLOBAL SEARCH",
    "priority": 1
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
