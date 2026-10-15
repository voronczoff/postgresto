--liquibase formatted sql
--changeset framework:seed-view-00a8d345c1 runOnChange:true splitStatements:false
INSERT INTO postgresto.${view.table}
  (id, jsondata)
VALUES (
  'postgresto.geo_countries|Default',
  $json$
  {
    "table": "geo_countries",
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
      "gdp": {
        "path": "gdp",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 21,
        "searchable": false
      },
      "tld": {
        "path": "tld",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 18
      },
      "Path": {
        "path": "Path",
        "type": "tree-auto",
        "width": 280,
        "locked": false,
        "visible": false,
        "orderList": 9
      },
      "flag": {
        "path": "flag",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 29,
        "searchable": false
      },
      "iso2": {
        "path": "iso2",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 12
      },
      "iso3": {
        "path": "iso3",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 10
      },
      "Level": {
        "path": "Level",
        "type": "tree-auto",
        "width": 72,
        "locked": false,
        "visible": false,
        "orderList": 7
      },
      "emoji": {
        "path": "emoji",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 2
      },
      "emojiU": {
        "path": "emojiU",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 28
      },
      "native": {
        "path": "native",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 19
      },
      "capital": {
        "path": "capital",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 14
      },
      "currency": {
        "path": "currency",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 15
      },
      "latitude": {
        "path": "latitude",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 26,
        "searchable": false
      },
      "longitude": {
        "path": "longitude",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 27,
        "searchable": false
      },
      "phonecode": {
        "path": "phonecode",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 13
      },
      "region_id": {
        "link": "regions",
        "path": "region_id",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 6,
        "searchable": false
      },
      "timezones": {
        "path": "timezones",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 35
      },
      "area_sq_km": {
        "path": "area_sq_km",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 23,
        "searchable": false
      },
      "created_at": {
        "path": "created_at",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 31
      },
      "created_by": {
        "path": "created_by",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 32
      },
      "population": {
        "path": "population",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 20,
        "searchable": false
      },
      "updated_at": {
        "path": "updated_at",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 33
      },
      "updated_by": {
        "path": "updated_by",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 34
      },
      "wikiDataId": {
        "path": "wikiDataId",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 30
      },
      "nationality": {
        "path": "nationality",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 22
      },
      "region_name": {
        "path": "region",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 8
      },
      "country_name": {
        "path": "name",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 3
      },
      "numeric_code": {
        "path": "numeric_code",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 11
      },
      "subregion_id": {
        "link": "subregions",
        "path": "subregion_id",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 4,
        "searchable": false
      },
      "translations": {
        "path": "translations",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 36
      },
      "currency_name": {
        "path": "currency_name",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 16
      },
      "subregion_name": {
        "path": "subregion",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 5
      },
      "currency_symbol": {
        "path": "currency_symbol",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 17
      },
      "postal_code_regex": {
        "path": "postal_code_regex",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 25
      },
      "postal_code_format": {
        "path": "postal_code_format",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 24
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
        "field": "subregion_id",
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
