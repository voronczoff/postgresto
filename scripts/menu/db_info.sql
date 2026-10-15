--liquibase formatted sql
--changeset framework:seed-menu-074b9a3b73 runOnChange:true splitStatements:false
INSERT INTO postgresto.${menu.table}
  (id, jsondata)
VALUES (
  'db_info',
  $json$
  {
    "icon": "InfoOutlined",
    "view": "/pages/dbinfo",
    "label": "DB Info",
    "parent": "tools",
    "priority": 3
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
