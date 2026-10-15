--liquibase formatted sql
--changeset framework:seed-menu-countries_tree runOnChange:true splitStatements:false
INSERT INTO postgresto.${menu.table}
  (id, jsondata)
VALUES (
  'countries_tree',
  $json$
  {
    "icon": "AccountTree",
    "view": "postgresto.geo_countries|regions and subregions and coutries",
    "label": "Countries Tree",
    "parent": "geo",
    "priority": 0
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
