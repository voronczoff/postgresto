--liquibase formatted sql
--changeset framework:seed-view-c7609c63a9 runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.demo_history|Default',
  $json$
  {
    "table": "demo_history",
    "schema": "postgresto",
    "columns": {
      "id": {
        "path": "id",
        "type": "text",
        "locked": true,
        "visible": false,
        "orderList": 4
      },
      "char": {
        "path": "jsondata->>char",
        "type": "text",
        "orderList": 18
      },
      "date": {
        "path": "jsondata->>date",
        "type": "date",
        "orderList": 7
      },
      "real": {
        "path": "jsondata->real",
        "type": "number",
        "orderList": 31
      },
      "text": {
        "path": "jsondata->>text",
        "type": "text",
        "orderList": 14
      },
      "time": {
        "path": "jsondata->>time",
        "type": "text",
        "orderList": 33
      },
      "uuid": {
        "path": "jsondata->>uuid",
        "type": "text",
        "orderList": 38
      },
      "bytea": {
        "path": "jsondata->>bytea",
        "type": "text",
        "orderList": 17
      },
      "level": {
        "path": "jsondata->level",
        "type": "number",
        "orderList": 11
      },
      "money": {
        "path": "jsondata->>money",
        "type": "text",
        "orderList": 28
      },
      "token": {
        "path": "jsondata->>token",
        "type": "text",
        "orderList": 15
      },
      "bigint": {
        "path": "jsondata->bigint",
        "type": "number",
        "orderList": 16
      },
      "json n": {
        "path": "jsondata->json->n",
        "type": "number",
        "orderList": 10
      },
      "number": {
        "path": "jsondata->number",
        "type": "number",
        "orderList": 12
      },
      "parent": {
        "path": "jsondata->>parent",
        "type": "text",
        "orderList": 30
      },
      "status": {
        "path": "jsondata->>status",
        "type": "text",
        "orderList": 13
      },
      "boolean": {
        "path": "jsondata->boolean",
        "type": "boolean",
        "orderList": 5,
        "searchable": false
      },
      "integer": {
        "path": "jsondata->integer",
        "type": "number",
        "orderList": 22
      },
      "jsonb n": {
        "path": "jsondata->jsonb->n",
        "type": "number",
        "orderList": 25
      },
      "numeric": {
        "path": "jsondata->numeric",
        "type": "number",
        "orderList": 29
      },
      "varchar": {
        "path": "jsondata->>varchar",
        "type": "text",
        "orderList": 39
      },
      "category": {
        "path": "jsondata->>category",
        "type": "text",
        "orderList": 6
      },
      "datetime": {
        "path": "jsondata->>datetime",
        "type": "datetime",
        "orderList": 8
      },
      "interval": {
        "path": "jsondata->>interval",
        "type": "text",
        "orderList": 23
      },
      "smallint": {
        "path": "jsondata->smallint",
        "type": "number",
        "orderList": 32
      },
      "record_id": {
        "path": "jsondata->>id",
        "type": "text",
        "locked": true,
        "visible": true,
        "orderList": 3
      },
      "timestamp": {
        "path": "jsondata->>timestamp",
        "type": "datetime",
        "orderList": 34
      },
      "created at": {
        "path": "jsondata->>created_at",
        "type": "datetime",
        "orderList": 19
      },
      "created by": {
        "path": "jsondata->>created_by",
        "type": "text",
        "orderList": 20
      },
      "json group": {
        "path": "jsondata->json->group",
        "type": "number",
        "orderList": 24
      },
      "json label": {
        "path": "jsondata->json->>label",
        "type": "text",
        "orderList": 9
      },
      "jsonb rank": {
        "path": "jsondata->jsonb->rank",
        "type": "number",
        "orderList": 26
      },
      "updated at": {
        "path": "jsondata->>updated_at",
        "type": "datetime",
        "orderList": 36
      },
      "updated by": {
        "path": "jsondata->>updated_by",
        "type": "text",
        "orderList": 37
      },
      "timestamptz": {
        "path": "jsondata->>timestamptz",
        "type": "datetime",
        "orderList": 35
      },
      "jsonb region": {
        "path": "jsondata->jsonb->>region",
        "type": "text",
        "orderList": 27
      },
      "$operation Type": {
        "path": "jsondata->>$operationType",
        "type": "text",
        "orderList": 2
      },
      "double precision": {
        "path": "jsondata->double_precision",
        "type": "number",
        "orderList": 21
      },
      "$transaction Date": {
        "path": "jsondata->>$transactionDate",
        "type": "datetime",
        "orderList": 1
      }
    },
    "sorting": [
      {
        "field": "jsondata->>$transactionDate",
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
