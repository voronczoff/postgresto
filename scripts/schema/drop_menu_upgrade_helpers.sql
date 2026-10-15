--liquibase formatted sql
--changeset postgresto:drop_menu_upgrade_helpers runOnChange:true runInTransaction:true splitStatements:false logicalFilePath:schema/cumulative_changelog.xml
-- Drop obsolete one-shot menu upgrade helpers (legacy nested menuitems[] path).
DROP FUNCTION IF EXISTS postgresto.backfill_menu_views(jsonb, text);
DROP FUNCTION IF EXISTS postgresto.strip_menu_models(jsonb);
