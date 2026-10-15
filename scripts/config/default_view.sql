--liquibase formatted sql
--changeset framework:seed-config-99286658f6 runOnChange:true splitStatements:false
INSERT INTO postgresto.${config.table}
  (id, jsondata)
VALUES (
  'default_view',
  $json$
  {
    "default_view": "postgresto.demo|Default"
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
