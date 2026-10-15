--liquibase formatted sql
--changeset framework:seed-config-053233181f runOnChange:true splitStatements:false
INSERT INTO postgresto.${config.table}
  (id, jsondata)
VALUES (
  'favicon',
  $json$
  {
    "favicon": "/favicon.svg"
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
