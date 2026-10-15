--liquibase formatted sql
--changeset postgresto:migrate_models_to_default_views runOnChange:true runInTransaction:true splitStatements:false logicalFilePath:schema/cumulative_changelog.xml
-- One-time: copy postgresto.model rows into default views
-- (`{schema}.{table}|Default` or `{schema}.{table}|{route}` when route≠table).
-- Renames tableName/apiTable → table, strips tree.levels[].model, drops name/pk/label.
-- Also migrates legacy `{route}|…` view ids and backfills named views.

DO $$
DECLARE
  models_table text := '${models.table}';
  views_table text := '${view.table}';
  has_models boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'postgresto'
      AND table_name = models_table
  ) INTO has_models;

  IF has_models THEN
    EXECUTE format($sql$
      INSERT INTO postgresto.%I (id, jsondata, created_at, created_by, updated_at, updated_by)
      SELECT
        (
          COALESCE(NULLIF(m.jsondata->>'schema', ''), 'postgresto')
          || '.'
          || COALESCE(
            NULLIF(m.jsondata->>'tableName', ''),
            NULLIF(m.jsondata->>'apiTable', ''),
            CASE
              WHEN m.id LIKE '%%_model' THEN left(m.id, length(m.id) - 6)
              ELSE m.id
            END
          )
          || '|'
          || CASE
            WHEN m.id LIKE '%%_model'
              AND left(m.id, length(m.id) - 6)
                <> COALESCE(
                  NULLIF(m.jsondata->>'tableName', ''),
                  NULLIF(m.jsondata->>'apiTable', ''),
                  left(m.id, length(m.id) - 6)
                )
            THEN left(m.id, length(m.id) - 6)
            ELSE 'Default'
          END
        ) AS id,
        (
          (m.jsondata - 'tableName' - 'apiTable' - 'label' - 'name' - 'pk')
          || jsonb_build_object(
            'schema', COALESCE(NULLIF(m.jsondata->>'schema', ''), 'postgresto'),
            'table', COALESCE(
              NULLIF(m.jsondata->>'tableName', ''),
              NULLIF(m.jsondata->>'apiTable', ''),
              CASE
                WHEN m.id LIKE '%%_model' THEN left(m.id, length(m.id) - 6)
                ELSE m.id
              END
            )
          )
          || CASE
            WHEN jsonb_typeof(m.jsondata->'tree'->'levels') = 'array' THEN
              jsonb_build_object(
                'tree',
                (m.jsondata->'tree')
                  || jsonb_build_object(
                    'levels',
                    (
                      SELECT COALESCE(jsonb_agg(
                        CASE
                          WHEN jsonb_typeof(level) = 'object' THEN level - 'model'
                          ELSE level
                        END
                      ), '[]'::jsonb)
                      FROM jsonb_array_elements(m.jsondata->'tree'->'levels') AS level
                    )
                  )
              )
            ELSE '{}'::jsonb
          END
        ) AS jsondata,
        m.created_at,
        m.created_by,
        m.updated_at,
        m.updated_by
      FROM postgresto.%I m
      ON CONFLICT (id) DO UPDATE
      SET
        jsondata = EXCLUDED.jsondata,
        updated_at = COALESCE(EXCLUDED.updated_at, now()),
        updated_by = EXCLUDED.updated_by
    $sql$, views_table, models_table);
  END IF;

  -- Rewrite legacy `{route}|name` view ids → `{schema}.{table}|name`.
  EXECUTE format($sql$
    WITH rewritten AS (
      SELECT
        v.id AS old_id,
        (
          COALESCE(
            NULLIF(v.jsondata->>'schema', ''),
            'postgresto'
          )
          || '.'
          || COALESCE(
            NULLIF(v.jsondata->>'table', ''),
            NULLIF(v.jsondata->>'tableName', ''),
            NULLIF(v.jsondata->>'apiTable', ''),
            split_part(v.id, '|', 1)
          )
          || '|'
          || split_part(v.id, '|', 2)
        ) AS new_id,
        (
          v.jsondata
          || jsonb_build_object(
            'schema', COALESCE(NULLIF(v.jsondata->>'schema', ''), 'postgresto'),
            'table', COALESCE(
              NULLIF(v.jsondata->>'table', ''),
              NULLIF(v.jsondata->>'tableName', ''),
              NULLIF(v.jsondata->>'apiTable', ''),
              split_part(v.id, '|', 1)
            )
          )
          - 'tableName' - 'apiTable'
        ) AS jsondata,
        v.created_at,
        v.created_by,
        v.updated_at,
        v.updated_by
      FROM postgresto.%I v
      WHERE v.id LIKE '%%|%%'
        AND v.id NOT LIKE '%%.%%|%%'
    )
    INSERT INTO postgresto.%I (id, jsondata, created_at, created_by, updated_at, updated_by)
    SELECT new_id, jsondata, created_at, created_by, updated_at, updated_by
    FROM rewritten
    ON CONFLICT (id) DO UPDATE
    SET
      jsondata = EXCLUDED.jsondata,
      updated_at = COALESCE(EXCLUDED.updated_at, now()),
      updated_by = EXCLUDED.updated_by
  $sql$, views_table, views_table);

  EXECUTE format($sql$
    DELETE FROM postgresto.%I v
    WHERE v.id LIKE '%%|%%'
      AND v.id NOT LIKE '%%.%%|%%'
  $sql$, views_table);

  -- Backfill catalog meta onto named views missing table/schema (pk is not stored).
  EXECUTE format($sql$
    UPDATE postgresto.%I v
    SET jsondata =
      (v.jsondata - 'pk')
      || CASE
        WHEN COALESCE(v.jsondata->>'table', '') = ''
          AND COALESCE(d.jsondata->>'table', '') <> ''
        THEN jsonb_build_object('table', d.jsondata->>'table')
        ELSE '{}'::jsonb
      END
      || CASE
        WHEN COALESCE(v.jsondata->>'schema', '') = ''
          AND COALESCE(d.jsondata->>'schema', '') <> ''
        THEN jsonb_build_object('schema', d.jsondata->>'schema')
        ELSE '{}'::jsonb
      END
    FROM postgresto.%I d
    WHERE (
        d.id LIKE '%%|Default'
        OR split_part(d.id, '|', 2) = split_part(split_part(d.id, '|', 1), '.', 2)
      )
      AND split_part(v.id, '|', 1) = split_part(d.id, '|', 1)
      AND v.id <> d.id
      AND (
        COALESCE(v.jsondata->>'table', '') = ''
        OR COALESCE(v.jsondata->>'schema', '') = ''
        OR v.jsondata ? 'pk'
      )
  $sql$, views_table, views_table);

  -- Strip legacy pk from every view document (PK comes from Postgres/OpenAPI).
  EXECUTE format($sql$
    UPDATE postgresto.%I
    SET jsondata = jsondata - 'pk'
    WHERE jsondata ? 'pk'
  $sql$, views_table);
END $$;
