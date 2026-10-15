--liquibase formatted sql
--changeset framework:seed-config-9fe70e30a3 runOnChange:true splitStatements:false
INSERT INTO postgresto.${config.table}
  (id, jsondata)
VALUES (
  'title_suffix',
  $json$
  {
    "title_suffix": "POSTGRESTO"
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
