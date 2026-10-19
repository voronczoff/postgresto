--liquibase formatted sql
--changeset framework:seed-view-e3f5d63bcb runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.search|Default',
  $json$
  {
    "table": "search",
    "schema": "postgresto",
    "columns": {
      "id": {
        "link": "@Record Link",
        "path": "id",
        "type": "text",
        "orderList": 1
      },
      "Index": {
        "path": "index",
        "type": "text",
        "visible": false,
        "orderList": 6,
        "searchable": false
      },
      "Table": {
        "link": "@Table Link",
        "path": "table",
        "type": "text",
        "orderList": 2
      },
      "Indexed At": {
        "path": "indexed_at",
        "type": "datetime",
        "orderList": 3
      },
      "Table Link": {
        "path": "'/data/' + String(fields.Table || '').replace(/\\./g, '/')",
        "type": "calculated",
        "visible": false,
        "orderList": 5
      },
      "Record Link": {
        "path": "'/data/' + String(fields.Table || '').replace(/\\./g, '/') + '/record/' + encodeURIComponent(String(fields.id ?? ''))",
        "type": "calculated",
        "visible": false,
        "orderList": 4
      }
    },
    "sorting": [
      {
        "field": "table",
        "order": "asc"
      }
    ],
    "rowcount": true,
    "selector": true,
    "description": "Global search index configuration."
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
