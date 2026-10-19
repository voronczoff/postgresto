--liquibase formatted sql
--changeset framework:seed-view-98635cbb0a runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.geo_subregions|Tree',
  $json$
  {
    "tree": {
      "levels": [
        {
          "id": "id",
          "name": "name",
          "table": "geo_regions"
        }
      ],
      "showTree": true,
      "fetchPerLevel": true
    },
    "table": "geo_subregions",
    "schema": "postgresto",
    "columns": {
      "id": {
        "path": "id",
        "type": "number",
        "locked": true,
        "visible": true,
        "orderList": 1,
        "searchable": false
      },
      "Path": {
        "path": "Path",
        "type": "tree-auto",
        "width": 280,
        "visible": false,
        "orderList": 10
      },
      "flag": {
        "path": "flag",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 7,
        "searchable": false
      },
      "name": {
        "path": "name",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 2
      },
      "Level": {
        "path": "Level",
        "type": "tree-auto",
        "width": 72,
        "visible": true,
        "orderList": 9
      },
      "region_id": {
        "path": "region_id",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 4,
        "searchable": false
      },
      "created_at": {
        "path": "created_at",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 5
      },
      "updated_at": {
        "path": "updated_at",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 6
      },
      "wikiDataId": {
        "path": "wikiDataId",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 8
      },
      "translations": {
        "path": "translations",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 3
      }
    },
    "filters": {
      "quickSearch": ""
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
