--liquibase formatted sql
--changeset postgresto:drop_model_table runOnChange:true runInTransaction:true splitStatements:false logicalFilePath:schema/cumulative_changelog.xml
-- Drop the retired model catalog table (defaults now live in view as `{schema}.{table}|Default`).

DO $$
DECLARE
  models_table text := 'model';
BEGIN
  EXECUTE format('DROP TRIGGER IF EXISTS %I_trg_log_history ON postgresto.%I', models_table, models_table);
  EXECUTE format('DROP TRIGGER IF EXISTS update_timestamp_%I ON postgresto.%I', models_table, models_table);
  EXECUTE format('DROP TABLE IF EXISTS postgresto.%I_history CASCADE', models_table);
  EXECUTE format('DROP TABLE IF EXISTS postgresto.%I CASCADE', models_table);
END $$;

NOTIFY pgrst, 'reload schema';
