--liquibase formatted sql
--changeset postgresto:rename_legacy_framework_tables runOnChange:true runInTransaction:true splitStatements:false logicalFilePath:schema/cumulative_changelog.xml
-- Upgrade the prior `tech_*` framework table names in place before the
-- canonical tables are created.
DO $$
DECLARE
  legacy_name text;
  canonical_name text;
BEGIN
  FOR legacy_name, canonical_name IN
    SELECT * FROM unnest(
      ARRAY[
        'tech_config',
        'tech_menu',
        'tech_views',
        'tech_models',
        'tech_search',
        'tech_config_history',
        'tech_menu_history',
        'tech_views_history',
        'tech_models_history'
      ],
      ARRAY[
        'config',
        'menu',
        'view',
        'model',
        'search',
        'config_history',
        'menu_history',
        'view_history',
        'model_history'
      ]
    )
  LOOP
    IF to_regclass(format('postgresto.%I', legacy_name)) IS NOT NULL
      AND to_regclass(format('postgresto.%I', canonical_name)) IS NULL THEN
      EXECUTE format(
        'ALTER TABLE postgresto.%I RENAME TO %I',
        legacy_name,
        canonical_name
      );
    END IF;
  END LOOP;
END;
$$;
