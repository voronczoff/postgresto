--liquibase formatted sql
--changeset framework:seed-config-fd70ea1de9 runOnChange:true splitStatements:false
INSERT INTO postgresto.${config.table}
  (id, jsondata)
VALUES (
  'schemas',
  $json$
  {
    "schemas": [
      "postgresto",
      "docs",
      "public"
    ]
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
