--liquibase formatted sql
--changeset framework:seed-view-647af238cb runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.geo_subregions|Default',
  $json$
  {
    "table": "geo_subregions",
    "schema": "postgresto",
    "columns": {
      "id": {
        "path": "id",
        "type": "number",
        "locked": true,
        "orderList": 1,
        "searchable": false
      },
      "flag": {
        "path": "flag",
        "type": "number",
        "orderList": 7,
        "searchable": false
      },
      "name": {
        "path": "name",
        "type": "text",
        "orderList": 2
      },
      "region_id": {
        "path": "region_id",
        "type": "number",
        "orderList": 4,
        "searchable": false
      },
      "created_at": {
        "path": "created_at",
        "type": "datetime",
        "orderList": 5
      },
      "updated_at": {
        "path": "updated_at",
        "type": "datetime",
        "orderList": 6
      },
      "wikiDataId": {
        "path": "wikiDataId",
        "type": "text",
        "orderList": 8
      },
      "translations": {
        "path": "translations",
        "type": "text",
        "orderList": 3
      }
    },
    "sorting": [
      {
        "field": "id",
        "order": "asc"
      }
    ],
    "rowcount": true,
    "selector": true
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
