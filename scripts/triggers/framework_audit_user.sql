--liquibase formatted sql
--changeset postgresto:trg-framework-audit-user runOnChange:true splitStatements:true logicalFilePath:triggers/cumulative_changelog.xml
-- BEFORE INSERT OR UPDATE → postgresto.set_audit_user() for framework document tables.
-- Framework table names are fixed.

DROP TRIGGER IF EXISTS set_audit_user_config ON postgresto.config;
CREATE TRIGGER set_audit_user_config
  BEFORE INSERT OR UPDATE ON postgresto.config
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.set_audit_user();

DROP TRIGGER IF EXISTS set_audit_user_menu ON postgresto.menu;
CREATE TRIGGER set_audit_user_menu
  BEFORE INSERT OR UPDATE ON postgresto.menu
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.set_audit_user();

DROP TRIGGER IF EXISTS set_audit_user_view ON postgresto.view;
CREATE TRIGGER set_audit_user_view
  BEFORE INSERT OR UPDATE ON postgresto.view
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.set_audit_user();
