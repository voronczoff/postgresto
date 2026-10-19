--liquibase formatted sql
--changeset framework:seed-config-aaf2320646 runOnChange:true splitStatements:false
INSERT INTO postgresto.config
  (id, jsondata)
VALUES (
  'title',
  $json$
  {
    "title": "POSTGRESTO"
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
