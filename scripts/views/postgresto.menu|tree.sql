--liquibase formatted sql
--changeset framework:seed-view-66f7fbe591 runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.menu|tree',
  $json$
  {
    "tree": {
      "levels": [
        {
          "id": "id",
          "name": "l",
          "table": "menu",
          "parent": "p"
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
        "orderList": 8
      },
      "p": {
        "path": "jsondata->>parent",
        "type": "text",
        "orderList": 9
      },
      "id": {
        "path": "id",
        "type": "text",
        "locked": true,
        "orderList": 1
      },
      "Path": {
        "path": "Path",
        "type": "tree-auto",
        "width": 280,
        "visible": false,
        "orderList": 14
      },
      "icon": {
        "path": "jsondata->>icon",
        "type": "text",
        "visible": false,
        "orderList": 7
      },
      "view": {
        "path": "jsondata->>view",
        "type": "text",
        "visible": false,
        "orderList": 12
      },
      "Level": {
        "path": "Level",
        "type": "tree-auto",
        "width": 72,
        "visible": false,
        "orderList": 13
      },
      "route": {
        "path": "jsondata->>route",
        "type": "text",
        "visible": false,
        "orderList": 11
      },
      "priority": {
        "path": "jsondata->priority",
        "type": "number",
        "visible": false,
        "orderList": 10
      },
      "created_at": {
        "path": "created_at",
        "type": "datetime",
        "visible": false,
        "orderList": 2
      },
      "created_by": {
        "path": "created_by",
        "type": "text",
        "visible": false,
        "orderList": 4
      },
      "updated_at": {
        "path": "updated_at",
        "type": "datetime",
        "visible": false,
        "orderList": 3
      },
      "updated_by": {
        "path": "updated_by",
        "type": "text",
        "visible": false,
        "orderList": 5
      },
      "collapsible": {
        "path": "jsondata->collapsible",
        "type": "boolean",
        "visible": false,
        "orderList": 6,
        "searchable": false
      }
    },
    "filters": {
      "preliminaryFilter": []
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
