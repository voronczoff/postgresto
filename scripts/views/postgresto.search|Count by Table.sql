--liquibase formatted sql
--changeset framework:seed-view-8cd91ba9b4 runOnChange:true splitStatements:false
INSERT INTO postgresto.${view.table}
  (id, jsondata)
VALUES (
  'postgresto.search|Count by Table',
  $json$
  {
    "table": "search",
    "schema": "postgresto",
    "columns": {
      "Count": {
        "path": "count()",
        "type": "number",
        "visible": true,
        "orderList": 2
      },
      "Table": {
        "path": "table",
        "type": "text",
        "label": "Table",
        "visible": true,
        "orderList": 1
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
