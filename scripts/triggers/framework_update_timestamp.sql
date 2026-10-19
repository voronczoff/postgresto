--liquibase formatted sql
--changeset postgresto:trg-framework-update-timestamp runOnChange:true splitStatements:true logicalFilePath:triggers/cumulative_changelog.xml
-- BEFORE UPDATE → postgresto.update_timestamp() for framework document tables.
-- Framework table names are fixed.

DROP TRIGGER IF EXISTS update_timestamp_config ON postgresto.config;
CREATE TRIGGER update_timestamp_config
  BEFORE UPDATE ON postgresto.config
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.update_timestamp();

DROP TRIGGER IF EXISTS update_timestamp_menu ON postgresto.menu;
CREATE TRIGGER update_timestamp_menu
  BEFORE UPDATE ON postgresto.menu
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.update_timestamp();

DROP TRIGGER IF EXISTS update_timestamp_view ON postgresto.view;
CREATE TRIGGER update_timestamp_view
  BEFORE UPDATE ON postgresto.view
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.update_timestamp();
