--liquibase formatted sql
--changeset framework:seed-view-735520d15e runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.view|Default2',
  $json$
  {
    "table": "view",
    "schema": "postgresto",
    "columns": {
      "id": {
        "path": "id",
        "type": "text",
        "locked": true,
        "orderList": 1
      },
      "jsondata": {
        "path": "jsondata",
        "type": "json",
        "orderList": 2
      },
      "created_at": {
        "path": "created_at",
        "type": "datetime",
        "orderList": 3
      },
      "created_by": {
        "path": "created_by",
        "type": "text",
        "orderList": 5
      },
      "updated_at": {
        "path": "updated_at",
        "type": "datetime",
        "orderList": 4
      },
      "updated_by": {
        "path": "updated_by",
        "type": "text",
        "orderList": 6
      }
    },
    "filters": {
      "preliminaryFilter": []
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
