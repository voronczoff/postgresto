--liquibase formatted sql
--changeset framework:seed-view-c7609c63a9 runOnChange:true splitStatements:false
INSERT INTO postgresto.${view.table}
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
        "orderList": 1
      },
      "date": {
        "path": "jsondata->>date",
        "type": "date",
        "orderList": 6
      },
      "text": {
        "path": "jsondata->>text",
        "type": "text",
        "orderList": 13
      },
      "level": {
        "path": "jsondata->level",
        "type": "number",
        "orderList": 10
      },
      "token": {
        "path": "jsondata->>token",
        "type": "text",
        "orderList": 14
      },
      "json n": {
        "path": "jsondata->json->n",
        "type": "number",
        "orderList": 9
      },
      "number": {
        "path": "jsondata->number",
        "type": "number",
        "orderList": 11
      },
      "status": {
        "path": "jsondata->>status",
        "type": "text",
        "orderList": 12
      },
      "boolean": {
        "path": "jsondata->boolean",
        "type": "boolean",
        "orderList": 4,
        "searchable": false
      },
      "category": {
        "path": "jsondata->>category",
        "type": "text",
        "orderList": 5
      },
      "datetime": {
        "path": "jsondata->>datetime",
        "type": "datetime",
        "orderList": 7
      },
      "json label": {
        "path": "jsondata->json->>label",
        "type": "text",
        "orderList": 8
      },
      "$operation Type": {
        "path": "jsondata->>$operationType",
        "type": "text",
        "orderList": 2
      },
      "$transaction Date": {
        "path": "jsondata->>$transactionDate",
        "type": "datetime",
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
