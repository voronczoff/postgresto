--liquibase formatted sql
--changeset framework:seed-config-cb08a120a0 runOnChange:true splitStatements:false
INSERT INTO postgresto.config
  (id, jsondata)
VALUES (
  'env_switcher',
  $json$
  {
    "env_switcher": [
      {
        "url": "http://localhost:5173/postgresto/",
        "icon": "Home",
        "label": "LocalHost",
        "title": "LH"
      },
      {
        "url": "http://m5.local:5173/postgresto/",
        "icon": "Home",
        "label": "M5",
        "title": "M5"
      },
      {
        "url": "http://localhost:7777/postgresto/",
        "icon": "Home",
        "label": "LocalHost Docker",
        "title": "LHD"
      },
      {
        "url": "http://m5.local:7777/postgresto/",
        "icon": "Home",
        "label": "M5 Docker",
        "title": "M5D"
      }
    ]
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
