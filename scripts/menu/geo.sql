--liquibase formatted sql
--changeset framework:seed-menu-7a8f6388fe runOnChange:true splitStatements:false
INSERT INTO postgresto.${menu.table}
  (id, jsondata)
VALUES (
  'geo',
  $json$
  {
    "icon": "Public",
    "label": "GEO",
    "parent": "lab",
    "priority": 3,
    "description": "data from dr5hn/countries-states-cities-database"
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
