--liquibase formatted sql
--changeset framework:seed-menu-subregions runOnChange:true splitStatements:false
INSERT INTO postgresto.${menu.table}
  (id, jsondata)
VALUES (
  'subregions',
  $json$
  {
    "icon": "ListAlt",
    "view": "postgresto.geo_subregions|Default",
    "label": "Subregions",
    "parent": "geo",
    "priority": 2
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
