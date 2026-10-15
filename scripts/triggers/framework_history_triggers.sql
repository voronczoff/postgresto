--liquibase formatted sql
--changeset postgresto:trg-framework-history runOnChange:true splitStatements:true logicalFilePath:triggers/cumulative_changelog.xml
-- AFTER INSERT/UPDATE/DELETE → postgresto.history_log_changes() for framework document tables.
-- Requires ${table}_history (created in schema/mandatory_tables.sql). Search has no history.

DROP TRIGGER IF EXISTS ${config.table}_trg_log_history ON postgresto.${config.table};
CREATE TRIGGER ${config.table}_trg_log_history
  AFTER INSERT OR UPDATE OR DELETE ON postgresto.${config.table}
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.history_log_changes();

DROP TRIGGER IF EXISTS ${menu.table}_trg_log_history ON postgresto.${menu.table};
CREATE TRIGGER ${menu.table}_trg_log_history
  AFTER INSERT OR UPDATE OR DELETE ON postgresto.${menu.table}
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.history_log_changes();

DROP TRIGGER IF EXISTS ${view.table}_trg_log_history ON postgresto.${view.table};
CREATE TRIGGER ${view.table}_trg_log_history
  AFTER INSERT OR UPDATE OR DELETE ON postgresto.${view.table}
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.history_log_changes();
