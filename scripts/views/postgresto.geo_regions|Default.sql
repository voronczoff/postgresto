--liquibase formatted sql
--changeset framework:seed-view-dd0dda4c4b runOnChange:true splitStatements:false
INSERT INTO postgresto.${view.table}
  (id, jsondata)
VALUES (
  'postgresto.geo_regions|Default',
  $json$
  {
    "table": "geo_regions",
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
        "orderList": 6,
        "searchable": false
      },
      "name": {
        "path": "name",
        "type": "text",
        "orderList": 2
      },
      "created_at": {
        "path": "created_at",
        "type": "datetime",
        "orderList": 4
      },
      "updated_at": {
        "path": "updated_at",
        "type": "datetime",
        "orderList": 5
      },
      "wikiDataId": {
        "path": "wikiDataId",
        "type": "text",
        "orderList": 7
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
