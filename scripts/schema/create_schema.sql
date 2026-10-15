--liquibase formatted sql
--changeset postgresto:docs_create_schema runOnChange:true runInTransaction:true splitStatements:false logicalFilePath:schema/cumulative_changelog.xml
-- The framework schema must exist before any technical tables are created.
CREATE SCHEMA IF NOT EXISTS postgresto;

-- PGSCHEMAS is validated as comma-separated simple identifiers by
-- liquibaseChangelogParams.sh before it is interpolated here.
DO $$
DECLARE
  schema_name text;
BEGIN
  FOREACH schema_name IN ARRAY string_to_array('${pgschemas}', ',')
  LOOP
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', schema_name);
  END LOOP;
END;
$$;
