--liquibase formatted sql
--changeset postgresto:rename_default_view_ids runOnChange:true runInTransaction:true splitStatements:false logicalFilePath:schema/cumulative_changelog.xml
-- Rename default view document ids `__default__` → `Default` and drop
-- top-level jsondata.name (display name is the id segment after `|`).

CREATE OR REPLACE FUNCTION postgresto.rename_menu_default_views(items jsonb)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT COALESCE(
    (
      SELECT jsonb_agg(
        CASE
          WHEN jsonb_typeof(elem) <> 'object' THEN elem
          ELSE
            (
              CASE
                WHEN elem ? 'view'
                  AND elem->>'view' LIKE '%|__default__'
                THEN jsonb_set(
                  elem,
                  '{view}',
                  to_jsonb(
                    regexp_replace(elem->>'view', '\|__default__$', '|Default')
                  )
                )
                ELSE elem
              END
            )
            || CASE
              WHEN jsonb_typeof(elem -> 'children') = 'array'
                AND jsonb_array_length(elem -> 'children') > 0
              THEN jsonb_build_object(
                'children',
                postgresto.rename_menu_default_views(elem -> 'children')
              )
              ELSE '{}'::jsonb
            END
        END
        ORDER BY ord
      )
      FROM jsonb_array_elements(COALESCE(items, '[]'::jsonb))
        WITH ORDINALITY AS t(elem, ord)
    ),
    '[]'::jsonb
  );
$$;

DO $$
DECLARE
  views_table text := '${view.table}';
  menu_table text := '${menu.table}';
BEGIN
  -- Prefer renaming when the target id is free; otherwise drop the legacy row.
  EXECUTE format($sql$
    UPDATE postgresto.%I AS v
    SET id = regexp_replace(v.id, '\|__default__$', '|Default')
    WHERE v.id LIKE '%%|__default__'
      AND NOT EXISTS (
        SELECT 1
        FROM postgresto.%I AS other
        WHERE other.id = regexp_replace(v.id, '\|__default__$', '|Default')
      )
  $sql$, views_table, views_table);

  EXECUTE format($sql$
    DELETE FROM postgresto.%I
    WHERE id LIKE '%%|__default__'
  $sql$, views_table);

  EXECUTE format($sql$
    UPDATE postgresto.%I
    SET jsondata = jsondata - 'name'
    WHERE jsondata ? 'name'
  $sql$, views_table);

  EXECUTE format($sql$
    UPDATE postgresto.%I m
    SET jsondata = jsonb_set(
      m.jsondata,
      '{menuitems}',
      postgresto.rename_menu_default_views(m.jsondata -> 'menuitems')
    )
    WHERE m.jsondata ? 'menuitems'
  $sql$, menu_table);
END $$;
