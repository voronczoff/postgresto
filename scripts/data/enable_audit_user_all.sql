--liquibase formatted sql
--changeset postgresto:enable_audit_user_all runOnChange:true runInTransaction:true splitStatements:false logicalFilePath:data/cumulative_changelog.xml
-- Enable set_audit_user on every non-history base table that has both
-- created_by and updated_by (framework, demo, bio, etc.).

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT t.table_schema, t.table_name
    FROM information_schema.tables t
    WHERE t.table_type = 'BASE TABLE'
      AND t.table_name NOT LIKE '%\_history' ESCAPE '\'
      AND EXISTS (
        SELECT 1
        FROM information_schema.columns c
        WHERE c.table_schema = t.table_schema
          AND c.table_name = t.table_name
          AND c.column_name = 'created_by'
      )
      AND EXISTS (
        SELECT 1
        FROM information_schema.columns u
        WHERE u.table_schema = t.table_schema
          AND u.table_name = t.table_name
          AND u.column_name = 'updated_by'
      )
    ORDER BY t.table_schema, t.table_name
  LOOP
    PERFORM postgresto.manage_audit_user(r.table_schema, r.table_name, true);
  END LOOP;
END;
$$;
