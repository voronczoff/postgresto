--liquibase formatted sql
--changeset framework:seed-config-5b8a8b56da runOnChange:true splitStatements:false
INSERT INTO postgresto.${config.table}
  (id, jsondata)
VALUES (
  'features',
  $json$
  {
    "features": {
      "cellCrossfade": false
    }
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
