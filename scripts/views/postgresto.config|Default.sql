--liquibase formatted sql
--changeset framework:seed-view-5309652276 runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.config|Default',
  $json$
  {
    "table": "config",
    "schema": "postgresto",
    "columns": {
      "id": {
        "path": "id",
        "type": "text",
        "locked": true,
        "visible": true,
        "orderList": 2
      },
      "JSON Data": {
        "path": "jsondata",
        "type": "json",
        "locked": false,
        "visible": true,
        "orderList": 3
      },
      "created_at": {
        "path": "created_at",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 6
      },
      "created_by": {
        "path": "created_by",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 4
      },
      "updated_at": {
        "path": "updated_at",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 1
      },
      "updated_by": {
        "path": "updated_by",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 5
      }
    },
    "filters": {
      "quickSearch": ""
    },
    "sorting": [
      {
        "field": "id",
        "order": "desc"
      }
    ],
    "rowcount": true,
    "selector": true
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
