--liquibase formatted sql
--changeset framework:seed-view-bc770f49e6 runOnChange:true splitStatements:false
INSERT INTO postgresto.view
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
        "orderList": 6
      },
      "date": {
        "path": "date",
        "type": "date",
        "locked": false,
        "visible": true,
        "orderList": 14
      },
      "json": {
        "path": "json",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 27
      },
      "real": {
        "path": "real",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 11,
        "searchable": false
      },
      "text": {
        "path": "text",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 4
      },
      "time": {
        "path": "time",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 15,
        "searchable": false
      },
      "uuid": {
        "path": "uuid",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 19,
        "searchable": false
      },
      "bytea": {
        "path": "bytea",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 22,
        "searchable": false
      },
      "jsonb": {
        "path": "jsonb",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 28
      },
      "money": {
        "path": "money",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 3,
        "searchable": false,
        "backgroundColor": "#a2ff80"
      },
      "bigint": {
        "path": "bigint",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 9,
        "textColor": "#ef0b0b",
        "searchable": false
      },
      "parent": {
        "link": "demo/id",
        "path": "parent",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 2
      },
      "boolean": {
        "path": "boolean",
        "type": "boolean",
        "locked": false,
        "visible": true,
        "orderList": 13
      },
      "integer": {
        "path": "integer",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 8,
        "searchable": false
      },
      "numeric": {
        "path": "numeric",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 10,
        "searchable": false
      },
      "varchar": {
        "path": "varchar",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 5
      },
      "interval": {
        "path": "interval",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 18,
        "searchable": false
      },
      "smallint": {
        "path": "smallint",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 7,
        "searchable": false
      },
      "timestamp": {
        "path": "timestamp",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 16
      },
      "created at": {
        "path": "created_at",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 24,
        "backgroundColor": "#ebebeb"
      },
      "created by": {
        "path": "created_by",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 23,
        "backgroundColor": "#ebebeb"
      },
      "json label": {
        "path": "json->>label",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 20
      },
      "updated at": {
        "path": "updated_at",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 25,
        "backgroundColor": "#ebebeb"
      },
      "updated by": {
        "path": "updated_by",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 26,
        "backgroundColor": "#ebebeb"
      },
      "jsonb flags": {
        "path": "jsonb->>flags",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 21
      },
      "timestamptz": {
        "path": "timestamptz",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 17
      },
      "double precision": {
        "path": "double_precision",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 12,
        "searchable": false
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
