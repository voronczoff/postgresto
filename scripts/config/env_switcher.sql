--liquibase formatted sql
--changeset framework:seed-config-cb08a120a0 runOnChange:true splitStatements:false
INSERT INTO postgresto.${config.table}
  (id, jsondata)
VALUES (
  'env_switcher',
  $json$
  {
    "env_switcher": [
      {
        "url": "http://localhost:5173/postgresto/",
        "icon": "Home",
        "label": "LH"
      },
      {
        "url": "http://m5.local:5173/postgresto/",
        "icon": "Home",
        "label": "M5"
      },
      {
        "url": "http://localhost:7777/postgresto/",
        "icon": "Home",
        "label": "LH DOCKER"
      },
      {
        "url": "http://m5.local:7777/postgresto/",
        "icon": "Home",
        "label": "M5 DOCLER"
      }
    ]
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
