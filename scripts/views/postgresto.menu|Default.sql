--liquibase formatted sql
--changeset framework:seed-view-08e76270b8 runOnChange:true splitStatements:false
INSERT INTO postgresto.${view.table}
  (id, jsondata)
VALUES (
  'postgresto.menu|Default',
  $json$
  {
    "table": "menu",
    "schema": "postgresto",
    "columns": {
      "id": {
        "path": "id",
        "type": "text",
        "locked": true,
        "orderList": 2
      },
      "view": {
        "path": "jsondata->>view",
        "type": "text",
        "orderList": 6
      },
      "label": {
        "path": "jsondata->>label",
        "type": "text",
        "orderList": 3
      },
      "parent": {
        "path": "jsondata->>parent",
        "type": "text",
        "orderList": 5
      },
      "priority": {
        "path": "jsondata->>priority",
        "type": "number",
        "orderList": 4
      },
      "created_at": {
        "path": "created_at",
        "type": "datetime",
        "orderList": 9
      },
      "created_by": {
        "path": "created_by",
        "type": "text",
        "orderList": 7
      },
      "updated_at": {
        "path": "updated_at",
        "type": "datetime",
        "orderList": 1
      },
      "updated_by": {
        "path": "updated_by",
        "type": "text",
        "orderList": 8
      }
    },
    "sorting": [
      {
        "field": "jsondata->>priority",
        "order": "asc"
      },
      {
        "field": "id",
        "order": "asc"
      }
    ],
    "description": "Sidebar menu structure stored in the database."
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
