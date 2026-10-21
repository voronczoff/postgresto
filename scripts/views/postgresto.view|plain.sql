--liquibase formatted sql
--changeset framework:seed-view-a7520059c4 runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.view|plain',
  $json$
  {
    "table": "view",
    "schema": "postgresto",
    "columns": {
      "id": {
        "path": "id",
        "type": "text",
        "locked": true,
        "visible": true,
        "orderList": 2
      },
      "tree": {
        "path": "jsondata->tree",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 10,
        "searchable": false
      },
      "table": {
        "path": "jsondata->>table",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 4
      },
      "schema": {
        "path": "jsondata->>schema",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 3
      },
      "columns": {
        "path": "jsondata->columns",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 11,
        "searchable": false
      },
      "filters": {
        "path": "jsondata->filters",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 9,
        "searchable": false
      },
      "sorting": {
        "path": "jsondata->sorting",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 8,
        "searchable": false
      },
      "rowcount": {
        "path": "jsondata->rowcount",
        "type": "boolean",
        "locked": false,
        "visible": true,
        "orderList": 7,
        "searchable": false
      },
      "selector": {
        "path": "jsondata->selector",
        "type": "boolean",
        "locked": false,
        "visible": true,
        "orderList": 6,
        "searchable": false
      },
      "created_at": {
        "path": "created_at",
        "type": "datetime",
        "locked": false,
        "visible": false,
        "orderList": 12
      },
      "created_by": {
        "path": "created_by",
        "type": "text",
        "locked": false,
        "visible": false,
        "orderList": 13
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
        "visible": false,
        "orderList": 14
      },
      "description": {
        "path": "jsondata->>description",
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
        "field": "updated_at",
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
