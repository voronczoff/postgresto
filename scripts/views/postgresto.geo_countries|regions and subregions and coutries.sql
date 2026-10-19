--liquibase formatted sql
--changeset framework:seed-view-a8a82f4bc8 runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.geo_countries|regions and subregions and coutries',
  $json$
  {
    "tree": {
      "levels": [
        {
          "id": "region_id",
          "name": "region_name",
          "table": "geo_regions"
        },
        {
          "id": "subregion_id",
          "name": "subregion_name",
          "table": "geo_subregions"
        },
        {
          "id": "country_id",
          "name": "country_name",
          "table": "geo_countries"
        }
      ],
      "showTree": true,
      "fetchPerLevel": true,
      "breadcrumbLabel": "name",
      "breadcrumbShowLevel": false
    },
    "table": "geo_countries",
    "schema": "postgresto",
    "columns": {
      "Path": {
        "path": "Path",
        "type": "tree-auto",
        "width": 280,
        "locked": false,
        "visible": false,
        "orderList": 8
      },
      "Level": {
        "path": "Level",
        "type": "tree-auto",
        "width": 72,
        "locked": false,
        "visible": false,
        "orderList": 7
      },
      "region_id": {
        "link": "regions",
        "path": "region_id",
        "type": "number",
        "visible": false,
        "orderList": 1,
        "searchable": false
      },
      "country_id": {
        "path": "id",
        "type": "number",
        "locked": true,
        "visible": false,
        "orderList": 5,
        "searchable": false
      },
      "region_name": {
        "path": "region",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 2
      },
      "country_name": {
        "path": "name",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 6
      },
      "subregion_id": {
        "link": "subregions",
        "path": "subregion_id",
        "type": "number",
        "locked": false,
        "visible": false,
        "orderList": 3,
        "searchable": false
      },
      "subregion_name": {
        "path": "subregion",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 4
      }
    },
    "filters": {
      "quickSearch": ""
    },
    "sorting": [
      {
        "field": "region_id",
        "order": "asc"
      },
      {
        "field": "subregion",
        "order": "asc"
      },
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
