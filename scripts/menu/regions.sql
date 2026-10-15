--liquibase formatted sql
--changeset framework:seed-menu-regions runOnChange:true splitStatements:false
INSERT INTO postgresto.${menu.table}
  (id, jsondata)
VALUES (
  'regions',
  $json$
  {
    "icon": "ListAlt",
    "view": "postgresto.geo_regions|Default",
    "label": "Regions",
    "parent": "geo",
    "priority": 3
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
