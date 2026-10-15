--liquibase formatted sql
--changeset framework:seed-config-04a9fba2f0 runOnChange:true splitStatements:false
INSERT INTO postgresto.${config.table}
  (id, jsondata)
VALUES (
  'brand',
  $json$
  {
    "brand": {
      "primary": "POST",
      "secondary": "GRESTO"
    }
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
