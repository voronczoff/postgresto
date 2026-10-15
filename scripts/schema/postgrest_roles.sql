--liquibase formatted sql
--changeset postgresto:postgrest_jwt_roles runOnChange:true runInTransaction:true splitStatements:false logicalFilePath:schema/cumulative_changelog.xml
-- PostgREST JWT roles: connect as the Liquibase/DB URI user (authenticator),
-- then SET ROLE to anon (no JWT) or authenticated (JWT role claim).
DO $$
DECLARE
  schema_name text;
  schemas text[];
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;

  -- DB URI role must be able to switch into claim roles.
  GRANT anon TO CURRENT_USER;
  GRANT authenticated TO CURRENT_USER;

  -- See other users' SQL text in pg_stat_statements / activity (dbinfo UI).
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pg_read_all_stats') THEN
    GRANT pg_read_all_stats TO authenticated;
  END IF;

  schemas := string_to_array('postgresto,' || '${pgschemas}', ',');
  FOREACH schema_name IN ARRAY schemas
  LOOP
    schema_name := btrim(schema_name);
    IF schema_name = '' THEN
      CONTINUE;
    END IF;

    EXECUTE format('GRANT USAGE ON SCHEMA %I TO authenticated', schema_name);
    EXECUTE format(
      'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA %I TO authenticated',
      schema_name
    );
    EXECUTE format(
      'GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA %I TO authenticated',
      schema_name
    );
    EXECUTE format(
      'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %I TO authenticated',
      schema_name
    );
    EXECUTE format(
      'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON TABLES TO authenticated',
      schema_name
    );
    EXECUTE format(
      'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON SEQUENCES TO authenticated',
      schema_name
    );
    EXECUTE format(
      'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT EXECUTE ON FUNCTIONS TO authenticated',
      schema_name
    );
  END LOOP;
END;
$$;
