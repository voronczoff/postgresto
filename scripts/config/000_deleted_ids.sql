--liquibase formatted sql
--changeset framework:sync-deleted-config-ids runOnChange:true splitStatements:false
-- removed-ids: ["base_path_candidates", "default_table", "root_cache_key", "toolbar_actions"]
DELETE FROM postgresto.config
WHERE id IN (
  'base_path_candidates',
  'default_table',
  'root_cache_key',
  'toolbar_actions'
);
