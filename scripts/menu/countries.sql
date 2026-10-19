--liquibase formatted sql
--changeset framework:seed-menu-countries runOnChange:true splitStatements:false
INSERT INTO postgresto.menu
  (id, jsondata)
VALUES (
  'countries',
  $json$
  {
    "icon": "ListAlt",
    "view": "postgresto.geo_countries|Default",
    "label": "Countries",
    "parent": "geo",
    "priority": 1
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
