--liquibase formatted sql
--changeset postgresto:docs_mandatory_tables runOnChange:true runInTransaction:true splitStatements:true logicalFilePath:schema/cumulative_changelog.xml
-- Framework tables always live in postgresto; only table names come from .env.
-- Substituted by Liquibase changelog parameters (see applyLiquibase*.sh).
-- Schema is ensured by create_schema.sql (Liquibase) before this file.

CREATE TABLE IF NOT EXISTS postgresto.config (
  id text PRIMARY KEY,
  jsondata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz,
  updated_at timestamptz,
  created_by text NULL,
  updated_by text NULL
);

CREATE TABLE IF NOT EXISTS postgresto.menu (
  id text PRIMARY KEY,
  jsondata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz,
  updated_at timestamptz,
  created_by text NULL,
  updated_by text NULL
);

CREATE TABLE IF NOT EXISTS postgresto.view (
  id text PRIMARY KEY,
  jsondata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz,
  updated_at timestamptz,
  created_by text NULL,
  updated_by text NULL
);

-- Existing installs created tables without audit columns; CREATE IF NOT EXISTS is a no-op.
ALTER TABLE postgresto.config
  ADD COLUMN IF NOT EXISTS created_at timestamptz,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS created_by text,
  ADD COLUMN IF NOT EXISTS updated_by text;

ALTER TABLE postgresto.menu
  ADD COLUMN IF NOT EXISTS created_at timestamptz,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS created_by text,
  ADD COLUMN IF NOT EXISTS updated_by text;

ALTER TABLE postgresto.view
  ADD COLUMN IF NOT EXISTS created_at timestamptz,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS created_by text,
  ADD COLUMN IF NOT EXISTS updated_by text;

-- History snapshots (written by postgresto.history_log_changes). Search has no history.
CREATE TABLE IF NOT EXISTS postgresto.config_history (
  id text PRIMARY KEY,
  jsondata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS postgresto.menu_history (
  id text PRIMARY KEY,
  jsondata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS postgresto.view_history (
  id text PRIMARY KEY,
  jsondata jsonb NOT NULL DEFAULT '{}'::jsonb
);


CREATE TABLE IF NOT EXISTS postgresto.search (
  "table" text NOT NULL,
  id text NOT NULL,
  "index" tsvector NOT NULL,
  indexed_at timestamptz DEFAULT now(),
  PRIMARY KEY ("table", id)
);

CREATE INDEX IF NOT EXISTS idx_search_index_gin
  ON postgresto.search USING GIN ("index");

CREATE INDEX IF NOT EXISTS search_table_indexed_at_idx
  ON postgresto.search ("table", indexed_at DESC);

NOTIFY pgrst, 'reload schema';
