--liquibase formatted sql
--changeset framework:seed-view-9359861db3 runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'postgresto.demo|Recursive Tree',
  $json$
  {
    "tree": {
      "levels": [
        {
          "id": "id",
          "name": "t",
          "table": "demo",
          "parent": "p"
        }
      ],
      "showTree": true,
      "breadcrumbLabel": "both"
    },
    "table": "demo",
    "schema": "postgresto",
    "columns": {
      "p": {
        "link": "demo",
        "path": "parent",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 2
      },
      "t": {
        "path": "text",
        "type": "text",
        "locked": false,
        "visible": true,
        "orderList": 3
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
        "orderList": 6
      },
      "Level": {
        "path": "Level",
        "type": "tree-auto",
        "width": 72,
        "locked": false,
        "visible": false,
        "orderList": 5
      },
      "jsondata level": {
        "path": "jsondata->level",
        "type": "number",
        "locked": false,
        "visible": false,
        "orderList": 4
      }
    },
    "filters": {
      "filterPane": null,
      "quickSearch": "",
      "preliminaryFilter": []
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
