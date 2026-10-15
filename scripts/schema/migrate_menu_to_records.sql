--liquibase formatted sql
--changeset postgresto:migrate_menu_to_records runOnChange:true runInTransaction:true splitStatements:false logicalFilePath:schema/cumulative_changelog.xml
-- Flatten legacy menu document (id=default, jsondata.menuitems[]) into one row per item.
-- Row id = menu item id (or generated section id). jsondata holds label, parent, priority, etc.

CREATE OR REPLACE FUNCTION postgresto.slugify_menu_section(label text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT COALESCE(
    NULLIF(
      regexp_replace(lower(COALESCE(label, '')), '[^[:alnum:]]+', '_', 'g'),
      ''
    ),
    'section'
  );
$$;

CREATE OR REPLACE FUNCTION postgresto.allocate_menu_section_id(
  label text,
  parent_id text,
  used_ids text[]
)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  base_slug text;
  candidate text;
  suffix int := 2;
BEGIN
  base_slug := postgresto.slugify_menu_section(label);
  candidate := base_slug;

  WHILE candidate = ANY (used_ids) LOOP
    candidate := base_slug || '_' || suffix::text;
    suffix := suffix + 1;
  END LOOP;

  RETURN candidate;
END;
$$;

CREATE OR REPLACE FUNCTION postgresto.allocate_menu_leaf_id(
  route_id text,
  parent_id text,
  used_ids text[]
)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  base_slug text;
  candidate text;
  suffix int := 2;
BEGIN
  IF NOT (route_id = ANY (used_ids)) THEN
    RETURN route_id;
  END IF;

  candidate := CASE
    WHEN parent_id IS NULL OR parent_id = '' THEN route_id || '_2'
    ELSE parent_id || '__' || route_id
  END;

  WHILE candidate = ANY (used_ids) LOOP
    candidate := CASE
      WHEN parent_id IS NULL OR parent_id = '' THEN route_id || '_' || suffix::text
      ELSE parent_id || '__' || route_id || '_' || suffix::text
    END;
    suffix := suffix + 1;
  END LOOP;

  RETURN candidate;
END;
$$;

CREATE OR REPLACE FUNCTION postgresto.flatten_menu_items_to_records(
  items jsonb,
  parent_id text DEFAULT NULL,
  used_ids text[] DEFAULT ARRAY[]::text[]
)
RETURNS TABLE (
  id text,
  jsondata jsonb,
  used_ids_out text[]
)
LANGUAGE plpgsql
AS $$
DECLARE
  elem jsonb;
  ord int;
  route_id text;
  section_id text;
  row_route text;
  child_rows record;
  next_used text[] := used_ids;
BEGIN
  ord := 0;
  FOR elem IN
    SELECT value
    FROM jsonb_array_elements(COALESCE(items, '[]'::jsonb)) AS t(value)
  LOOP
    route_id := NULLIF(trim(COALESCE(elem ->> 'id', elem ->> 'name', '')), '');
    row_route := NULL;

    IF route_id IS NOT NULL THEN
      section_id := postgresto.allocate_menu_leaf_id(route_id, parent_id, next_used);
      IF section_id <> route_id THEN
        row_route := route_id;
      END IF;
    ELSE
      section_id := postgresto.allocate_menu_section_id(
        elem ->> 'label',
        parent_id,
        next_used
      );
    END IF;

    next_used := next_used || section_id;

    jsondata := jsonb_strip_nulls(
      jsonb_build_object(
        'label', COALESCE(NULLIF(trim(elem ->> 'label'), ''), section_id),
        'priority', ord,
        'parent', parent_id,
        'route', row_route,
        'icon', elem ->> 'icon',
        'view', elem ->> 'view',
        'collapsible', CASE WHEN (elem ->> 'collapsible')::boolean THEN true ELSE NULL END,
        'query', elem ->> 'query'
      )
    );
    jsondata := jsondata - 'parent' || CASE
      WHEN parent_id IS NULL OR parent_id = '' THEN '{}'::jsonb
      ELSE jsonb_build_object('parent', parent_id)
    END;

    id := section_id;
    used_ids_out := next_used;
    RETURN NEXT;

    IF jsonb_typeof(elem -> 'children') = 'array'
      AND jsonb_array_length(elem -> 'children') > 0
    THEN
      FOR child_rows IN
        SELECT *
        FROM postgresto.flatten_menu_items_to_records(
          elem -> 'children',
          section_id,
          next_used
        )
      LOOP
        id := child_rows.id;
        jsondata := child_rows.jsondata;
        used_ids_out := child_rows.used_ids_out;
        next_used := child_rows.used_ids_out;
        RETURN NEXT;
      END LOOP;
    END IF;

    ord := ord + 1;
  END LOOP;
END;
$$;

DO $$
DECLARE
  menu_table text := '${menu.table}';
  legacy_items jsonb;
BEGIN
  EXECUTE format(
    $sql$
      SELECT COALESCE(jsondata -> 'menuitems', jsondata -> 'items')
      FROM postgresto.%I
      WHERE id = 'default'
    $sql$,
    menu_table
  )
  INTO legacy_items;

  IF legacy_items IS NULL THEN
    RETURN;
  END IF;

  EXECUTE format(
    $sql$
      INSERT INTO postgresto.%I (id, jsondata)
      SELECT f.id, f.jsondata
      FROM postgresto.flatten_menu_items_to_records($1) AS f
      ON CONFLICT (id) DO UPDATE
      SET jsondata = EXCLUDED.jsondata
    $sql$,
    menu_table
  )
  USING legacy_items;

  EXECUTE format(
    $sql$ DELETE FROM postgresto.%I WHERE id = 'default' $sql$,
    menu_table
  );
END $$;

NOTIFY pgrst, 'reload schema';
