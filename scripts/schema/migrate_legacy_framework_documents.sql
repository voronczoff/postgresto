--liquibase formatted sql
--changeset postgresto:migrate_legacy_framework_documents runOnChange:true runInTransaction:true splitStatements:false logicalFilePath:schema/cumulative_changelog.xml
-- Update framework documents and generated model ids after table renaming.
DO $$
DECLARE
  old_name text;
  new_name text;
  has_models boolean;
BEGIN
  FOR old_name, new_name IN
    SELECT * FROM unnest(
      ARRAY['tech_config', 'tech_menu', 'tech_views', 'tech_models', 'tech_search', 'tech_tables'],
      ARRAY['config', 'menu', 'view', 'model', 'search', 'tables']
    )
  LOOP
    UPDATE postgresto.config
    SET jsondata = replace(jsondata::text, old_name, new_name)::jsonb
    WHERE jsondata::text LIKE '%' || old_name || '%';

    UPDATE postgresto.menu
    SET jsondata = replace(jsondata::text, old_name, new_name)::jsonb
    WHERE jsondata::text LIKE '%' || old_name || '%';

    UPDATE postgresto.view
    SET jsondata = replace(jsondata::text, old_name, new_name)::jsonb
    WHERE jsondata::text LIKE '%' || old_name || '%';
  END LOOP;

  -- model may already be gone (fresh install or post drop_model_table).
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'postgresto'
      AND table_name = 'model'
  ) INTO has_models;

  IF has_models THEN
    DELETE FROM postgresto.model
    WHERE id IN (
      'config_model',
      'menu_model',
      'view_model',
      'model_model',
      'search_model',
      'tables_model'
    );

    UPDATE postgresto.model
    SET id = CASE id
      WHEN 'tech_config_model' THEN 'config_model'
      WHEN 'tech_menu_model' THEN 'menu_model'
      WHEN 'tech_views_model' THEN 'view_model'
      WHEN 'tech_models_model' THEN 'model_model'
      WHEN 'tech_search_model' THEN 'search_model'
      WHEN 'tech_tables_model' THEN 'tables_model'
      ELSE id
    END
    WHERE id IN (
      'tech_config_model',
      'tech_menu_model',
      'tech_views_model',
      'tech_models_model',
      'tech_search_model',
      'tech_tables_model'
    );
  END IF;
END;
$$;
