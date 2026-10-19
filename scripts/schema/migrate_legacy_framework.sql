--liquibase formatted sql
--changeset postgresto:migrate_legacy_tables runOnChange:true runInTransaction:true splitStatements:false logicalFilePath:schema/cumulative_changelog.xml
-- Preserve framework documents from pre-postgresto deployments. Only
-- id/jsondata are copied: the mandatory-table migration supplies audit columns.
DO $$
DECLARE
  source_schema text;
  legacy_name text;
  canonical_name text;
BEGIN
  FOREACH source_schema IN ARRAY string_to_array('${pgschemas}', ',')
  LOOP
    FOR legacy_name, canonical_name IN
      SELECT * FROM unnest(
        ARRAY[
          'tech_config',
          'tech_menu',
          'tech_views',
          'tech_models',
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
          'config_history',
          'menu_history',
          'view_history',
          'model_history'
        ]
      )
    LOOP
      IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = source_schema
          AND table_name = legacy_name
          AND table_type = 'BASE TABLE'
      ) THEN
        EXECUTE format(
          'INSERT INTO postgresto.%1$I (id, jsondata)
           SELECT id, jsondata FROM %2$I.%3$I
           ON CONFLICT (id) DO NOTHING',
          canonical_name,
          source_schema,
          legacy_name
        );
      END IF;
    END LOOP;
  END LOOP;
END;
$$;
