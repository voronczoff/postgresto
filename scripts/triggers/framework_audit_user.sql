--liquibase formatted sql
--changeset postgresto:trg-framework-audit-user runOnChange:true splitStatements:true logicalFilePath:triggers/cumulative_changelog.xml
-- BEFORE INSERT OR UPDATE → postgresto.set_audit_user() for framework document tables.
-- Table names from Liquibase -D / schema changelog properties (VITE_*_TABLE).

DROP TRIGGER IF EXISTS set_audit_user_${config.table} ON postgresto.${config.table};
CREATE TRIGGER set_audit_user_${config.table}
  BEFORE INSERT OR UPDATE ON postgresto.${config.table}
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.set_audit_user();

DROP TRIGGER IF EXISTS set_audit_user_${menu.table} ON postgresto.${menu.table};
CREATE TRIGGER set_audit_user_${menu.table}
  BEFORE INSERT OR UPDATE ON postgresto.${menu.table}
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.set_audit_user();

DROP TRIGGER IF EXISTS set_audit_user_${view.table} ON postgresto.${view.table};
CREATE TRIGGER set_audit_user_${view.table}
  BEFORE INSERT OR UPDATE ON postgresto.${view.table}
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.set_audit_user();
