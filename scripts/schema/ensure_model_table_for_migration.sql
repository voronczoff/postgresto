--liquibase formatted sql
--changeset postgresto:ensure_model_table_for_migration runOnChange:true runInTransaction:true splitStatements:true logicalFilePath:schema/cumulative_changelog.xml

CREATE TABLE IF NOT EXISTS postgresto.model (
  id text PRIMARY KEY,
  jsondata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz,
  updated_at timestamptz,
  created_by text NULL,
  updated_by text NULL
);
CREATE TABLE IF NOT EXISTS postgresto.model_history (
  id text PRIMARY KEY,
  jsondata jsonb NOT NULL DEFAULT '{}'::jsonb
);

