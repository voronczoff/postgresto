--liquibase formatted sql
--changeset framework:seed-view-50d891f9bf runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.menu|tree2',
  $json$
  {
    "tree": {
      "levels": [
        {
          "id": "id",
          "name": "l",
          "table": "menu",
          "parent": "p"
        },
        {
          "id": "v",
          "name": "v",
          "table": "view"
        }
      ],
      "showTree": true
    },
    "table": "menu",
    "schema": "postgresto",
    "columns": {
      "l": {
        "path": "jsondata->>label",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 8
      },
      "p": {
        "path": "jsondata->>parent",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 9
      },
      "v": {
        "path": "jsondata->>view",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 12
      },
      "id": {
        "path": "id",
        "type": "text",
        "locked": true,
        "visible": true,
        "orderList": 1
      },
      "Path": {
        "path": "Path",
        "type": "tree-auto",
        "width": 280,
        "locked": false,
        "visible": false,
        "orderList": 14
      },
      "icon": {
        "path": "jsondata->>icon",
        "type": "text",
        "locked": false,
        "visible": false,
        "orderList": 7
      },
      "Level": {
        "path": "Level",
        "type": "tree-auto",
        "width": 72,
        "locked": false,
        "visible": false,
        "orderList": 13
      },
      "route": {
        "path": "jsondata->>route",
        "type": "text",
        "locked": false,
        "visible": false,
        "orderList": 11
      },
      "priority": {
        "path": "jsondata->priority",
        "type": "number",
        "locked": false,
        "visible": false,
        "orderList": 10
      },
      "created_at": {
        "path": "created_at",
        "type": "datetime",
        "locked": false,
        "visible": false,
        "orderList": 2
      },
      "created_by": {
        "path": "created_by",
        "type": "text",
        "locked": false,
        "visible": false,
        "orderList": 4
      },
      "updated_at": {
        "path": "updated_at",
        "type": "datetime",
        "locked": false,
        "visible": false,
        "orderList": 3
      },
      "updated_by": {
        "path": "updated_by",
        "type": "text",
        "locked": false,
        "visible": false,
        "orderList": 5
      },
      "collapsible": {
        "path": "jsondata->collapsible",
        "type": "boolean",
        "locked": false,
        "visible": false,
        "orderList": 6,
        "searchable": false
      }
    },
    "filters": {
      "quickSearch": ""
    },
    "sorting": [
      {
        "field": "jsondata->priority",
        "order": "asc"
      }
    ],
    "rowcount": true,
    "selector": true,
    "description": "Sidebar menu structure stored in the database."
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
