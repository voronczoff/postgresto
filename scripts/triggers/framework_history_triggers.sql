--liquibase formatted sql
--changeset postgresto:trg-framework-history runOnChange:true splitStatements:true logicalFilePath:triggers/cumulative_changelog.xml
-- AFTER INSERT/UPDATE/DELETE → postgresto.history_log_changes() for framework document tables.
-- Requires ${table}_history (created in schema/mandatory_tables.sql). Search has no history.

DROP TRIGGER IF EXISTS config_trg_log_history ON postgresto.config;
CREATE TRIGGER config_trg_log_history
  AFTER INSERT OR UPDATE OR DELETE ON postgresto.config
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.history_log_changes();

DROP TRIGGER IF EXISTS menu_trg_log_history ON postgresto.menu;
CREATE TRIGGER menu_trg_log_history
  AFTER INSERT OR UPDATE OR DELETE ON postgresto.menu
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.history_log_changes();

DROP TRIGGER IF EXISTS view_trg_log_history ON postgresto.view;
CREATE TRIGGER view_trg_log_history
  AFTER INSERT OR UPDATE OR DELETE ON postgresto.view
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.history_log_changes();
