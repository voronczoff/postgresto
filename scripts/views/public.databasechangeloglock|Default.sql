--liquibase formatted sql
--changeset framework:seed-view-c5a7070730 runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'public.databasechangeloglock|Default',
  $json$
  {
    "table": "databasechangeloglock",
    "schema": "public",
    "columns": {
      "id": {
        "path": "id",
        "type": "number",
        "locked": true,
        "orderList": 1,
        "searchable": false
      },
      "locked": {
        "path": "locked",
        "type": "boolean",
        "orderList": 2
      },
      "lockedby": {
        "path": "lockedby",
        "type": "text",
        "orderList": 4
      },
      "lockgranted": {
        "path": "lockgranted",
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
