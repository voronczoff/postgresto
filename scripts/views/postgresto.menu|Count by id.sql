--liquibase formatted sql
--changeset framework:seed-view-aa08b5a66a runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.menu|Count by id',
  $json$
  {
    "table": "menu",
    "schema": "postgresto",
    "columns": {
      "id": {
        "path": "id",
        "type": "text",
        "label": "id",
        "visible": true,
        "orderList": 1
      },
      "Count": {
        "path": "count()",
        "type": "number",
        "visible": true,
        "orderList": 2
      }
    },
    "filters": {
      "filterPane": null,
      "quickSearch": "",
      "preliminaryFilter": []
    },
    "sorting": [
      {
        "field": "count()",
        "order": "desc"
      }
    ]
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
