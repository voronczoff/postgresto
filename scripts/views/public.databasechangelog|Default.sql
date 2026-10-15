--liquibase formatted sql
--changeset framework:seed-view-e350e286fc runOnChange:true splitStatements:false
INSERT INTO postgresto.${view.table}
  (id, jsondata)
VALUES (
  'public.databasechangelog|Default',
  $json$
  {
    "table": "databasechangelog",
    "schema": "public",
    "columns": {
      "id": {
        "path": "id",
        "type": "text",
        "orderList": 1
      },
      "tag": {
        "path": "tag",
        "type": "text",
        "orderList": 10
      },
      "author": {
        "path": "author",
        "type": "text",
        "orderList": 2
      },
      "labels": {
        "path": "labels",
        "type": "text",
        "orderList": 13
      },
      "md5sum": {
        "path": "md5sum",
        "type": "text",
        "orderList": 7
      },
      "comments": {
        "path": "comments",
        "type": "text",
        "orderList": 9
      },
      "contexts": {
        "path": "contexts",
        "type": "text",
        "orderList": 12
      },
      "exectype": {
        "path": "exectype",
        "type": "text",
        "orderList": 6
      },
      "filename": {
        "path": "filename",
        "type": "text",
        "orderList": 3
      },
      "liquibase": {
        "path": "liquibase",
        "type": "text",
        "orderList": 11
      },
      "description": {
        "path": "description",
        "type": "text",
        "orderList": 8
      },
      "dateexecuted": {
        "path": "dateexecuted",
        "type": "datetime",
        "orderList": 4
      },
      "deployment_id": {
        "path": "deployment_id",
        "type": "text",
        "orderList": 14
      },
      "orderexecuted": {
        "path": "orderexecuted",
        "type": "number",
        "orderList": 5,
        "searchable": false
      }
    },
    "sorting": [],
    "rowcount": true,
    "selector": true
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
