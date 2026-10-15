--liquibase formatted sql
--changeset postgresto:trg-framework-update-timestamp runOnChange:true splitStatements:true logicalFilePath:triggers/cumulative_changelog.xml
-- BEFORE UPDATE → postgresto.update_timestamp() for framework document tables.
-- Table names from Liquibase -D / schema changelog properties (VITE_*_TABLE).

DROP TRIGGER IF EXISTS update_timestamp_${config.table} ON postgresto.${config.table};
CREATE TRIGGER update_timestamp_${config.table}
  BEFORE UPDATE ON postgresto.${config.table}
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.update_timestamp();

DROP TRIGGER IF EXISTS update_timestamp_${menu.table} ON postgresto.${menu.table};
CREATE TRIGGER update_timestamp_${menu.table}
  BEFORE UPDATE ON postgresto.${menu.table}
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.update_timestamp();

DROP TRIGGER IF EXISTS update_timestamp_${view.table} ON postgresto.${view.table};
CREATE TRIGGER update_timestamp_${view.table}
  BEFORE UPDATE ON postgresto.${view.table}
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.update_timestamp();
