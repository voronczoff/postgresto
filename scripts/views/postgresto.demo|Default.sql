--liquibase formatted sql
--changeset framework:seed-view-bc770f49e6 runOnChange:true splitStatements:false
INSERT INTO postgresto.${view.table}
  (id, jsondata)
VALUES (
  'postgresto.demo|Default',
  $json$
  {
    "table": "demo",
    "schema": "postgresto",
    "columns": {
      "id": {
        "path": "id",
        "type": "text",
        "locked": true,
        "visible": true,
        "orderList": 1
      },
      "char": {
        "path": "char",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 11
      },
      "date": {
        "path": "jsondata->>date",
        "type": "date",
        "locked": false,
        "visible": true,
        "orderList": 6
      },
      "json": {
        "path": "jsondata->json",
        "type": "json",
        "locked": false,
        "visible": false,
        "orderList": 9
      },
      "real": {
        "path": "real",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 16
      },
      "text": {
        "path": "jsondata->>text",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 3
      },
      "time": {
        "path": "time",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 20,
        "searchable": false
      },
      "uuid": {
        "path": "uuid",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 24,
        "searchable": false
      },
      "bytea": {
        "path": "bytea",
        "type": "text",
        "locked": false,
        "visible": false,
        "orderList": 29,
        "searchable": false
      },
      "flags": {
        "path": "jsonb->>flags",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 26
      },
      "label": {
        "path": "json->>label",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 25
      },
      "money": {
        "path": "money",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 27,
        "searchable": false,
        "backgroundColor": "#a2ff80"
      },
      "bigint": {
        "path": "bigint",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 14
      },
      "date 2": {
        "path": "date",
        "type": "date",
        "locked": false,
        "visible": true,
        "orderList": 19
      },
      "number": {
        "path": "jsondata->number",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 4
      },
      "parent": {
        "link": "demo/id",
        "path": "parent",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 2
      },
      "text 2": {
        "path": "text",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 8
      },
      "boolean": {
        "path": "jsondata->boolean",
        "type": "boolean",
        "width": 0,
        "locked": false,
        "visible": true,
        "orderList": 5
      },
      "integer": {
        "path": "integer",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 13
      },
      "numeric": {
        "path": "numeric",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 15
      },
      "varchar": {
        "path": "varchar",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 10
      },
      "datetime": {
        "path": "jsondata->>datetime",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 7
      },
      "interval": {
        "path": "interval",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 23,
        "searchable": false
      },
      "smallint": {
        "path": "smallint",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 12
      },
      "boolean 2": {
        "path": "boolean",
        "type": "boolean",
        "locked": false,
        "visible": true,
        "orderList": 18
      },
      "timestamp": {
        "path": "timestamp",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 21
      },
      "created_at": {
        "path": "created_at",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 28,
        "backgroundColor": "#ebebeb"
      },
      "created_by": {
        "path": "created_by",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 30,
        "backgroundColor": "#ebebeb"
      },
      "updated_at": {
        "path": "updated_at",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 31,
        "backgroundColor": "#ebebeb"
      },
      "updated_by": {
        "path": "updated_by",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 32,
        "backgroundColor": "#ebebeb"
      },
      "timestamptz": {
        "path": "timestamptz",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 22
      },
      "double_precision": {
        "path": "double_precision",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 17
      }
    },
    "filters": {
      "filterPane": null,
      "quickSearch": "",
      "preliminaryFilter": []
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
