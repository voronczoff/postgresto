--liquibase formatted sql
--changeset framework:seed-view-8c00dfdc83 runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.demo_history|test',
  $json$
  {
    "table": "demo_history",
    "schema": "postgresto",
    "columns": {
      "id": {
        "path": "id",
        "type": "text",
        "locked": false,
        "visible": false,
        "orderList": 3
      },
      "What": {
        "path": "jsondata->>$operationType",
        "type": "",
        "locked": false,
        "visible": false,
        "orderList": 2
      },
      "When": {
        "path": "jsondata->>$transactionDate",
        "type": "datetime",
        "locked": false,
        "visible": false,
        "orderList": 1
      },
      "JSON Date": {
        "path": "jsondata->>date",
        "type": "date",
        "locked": false,
        "visible": true,
        "orderList": 8
      },
      "JSON Text": {
        "path": "jsondata->>text",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 4
      },
      "JSON Number": {
        "path": "jsondata->number",
        "type": "number",
        "locked": false,
        "visible": false,
        "orderList": 5
      },
      "JSON Boolean": {
        "path": "jsondata->boolean",
        "type": "boolean",
        "locked": false,
        "visible": true,
        "orderList": 6
      },
      "JSON Date Time": {
        "path": "jsondata->>datetime",
        "type": "datetime",
        "locked": false,
        "visible": true,
        "orderList": 9
      },
      "jsondata level": {
        "path": "jsondata->level",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 12
      },
      "jsondata token": {
        "path": "jsondata->>token",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 14
      },
      "jsondata json n": {
        "path": "jsondata->json->n",
        "type": "number",
        "locked": false,
        "visible": true,
        "orderList": 11
      },
      "jsondata status": {
        "path": "jsondata->>status",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 13
      },
      "jsondata category": {
        "path": "jsondata->>category",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 7
      },
      "jsondata json label": {
        "path": "jsondata->json->>label",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 10
      }
    },
    "sorting": [
      {
        "field": "id",
        "order": "asc"
      }
    ]
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
