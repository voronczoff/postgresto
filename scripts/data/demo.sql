--liquibase formatted sql
--changeset framework:sample_data runOnChange:true runInTransaction:true splitStatements:false logicalFilePath:data/cumulative_changelog.xml
-- Sample / demo tables for local UI exploration.

-- Remove the previous sample location (the first configured application schema)
-- before creating the canonical postgresto demo table.
DROP TABLE IF EXISTS ${appschema}.demo;
DROP TABLE IF EXISTS ${appschema}.demo_history;

CREATE TABLE postgresto.demo (
  id text PRIMARY KEY,
  parent text REFERENCES postgresto.demo (id),
  -- Main PostgreSQL types as columns (names match types)
  text text,
  varchar varchar(64),
  char char(1),
  smallint smallint,
  integer integer,
  bigint bigint,
  numeric numeric(14, 4),
  real real,
  double_precision double precision,
  boolean boolean,
  date date,
  time time,
  timestamp timestamp without time zone,
  timestamptz timestamptz,
  interval interval,
  uuid uuid,
  json json,
  jsonb jsonb,
  money money,
  bytea bytea,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by text,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by text
);

-- History snapshots for postgresto.demo (written by postgresto.history_log_changes).
CREATE TABLE postgresto.demo_history (
  id text PRIMARY KEY,
  jsondata jsonb NOT NULL DEFAULT '{}'::jsonb
);

-- Attach history logging before seed INSERT so CREATE snapshots are recorded.
DROP TRIGGER IF EXISTS demo_trg_log_history ON postgresto.demo;
CREATE TRIGGER demo_trg_log_history
  AFTER INSERT OR UPDATE OR DELETE ON postgresto.demo
  FOR EACH ROW
  EXECUTE FUNCTION postgresto.history_log_changes();



-- 1000 demo rows in a natural 5-level org tree (all depths present).
-- Fan-out is uneven (squared hash → busier early siblings). Roots 4–5 have
-- no children (leaf orgs). Useful for recursive tree, search, sort, filter,
-- timezone, and typed-column scenarios.
--
--   L1  orgs        1–5      (DEMO-0004 / DEMO-0005 are childless roots)
--   L2  divisions   6–50     (parents only among fertile roots 1–3)
--   L3  regions     51–200
--   L4  teams       201–500
--   L5  tasks       501–1000
INSERT INTO postgresto.demo (
  id, parent, text, varchar, char,
  smallint, integer, bigint, numeric, real, double_precision,
  boolean, date, time, timestamp, timestamptz, interval, uuid,
  json, jsonb, money, bytea,
  created_by, updated_by
)
SELECT
  'DEMO-' || lpad(i::text, 4, '0'),
  CASE
    WHEN depth.lvl = 1 THEN NULL
    ELSE 'DEMO-' || lpad(
      (
        depth.plo
        + least(
            depth.pspan - 1,
            floor(power((h.h1 % 10000)::numeric / 10000.0, 2) * depth.pspan)::int
          )
      )::text,
      4,
      '0'
    )
  END,
  -- Human-readable titles shaped by tree depth; a few shared / unicode edge rows
  CASE
    WHEN i % 40 = 0 THEN 'Shared catalog sample'
    WHEN i % 73 = 0 THEN 'Café résumé — Zürich / São Paulo'
    WHEN i % 91 = 0 THEN 'Line with "quotes", commas, & ampersands'
    WHEN i IN (4, 5) THEN w.adj || ' ' || w.noun || ' Group (standalone)'
    ELSE
      CASE depth.lvl
        WHEN 1 THEN w.adj || ' ' || w.noun || ' Group'
        WHEN 2 THEN w.adj || ' ' || w.noun || ' Division'
        WHEN 3 THEN w.city || ' Region'
        WHEN 4 THEN w.person || ' — ' || w.noun || ' Team'
        ELSE w.noun || ' Task · ' || w.city
      END
  END,
  -- Short codes under varchar(64): SKU-like, with a few deliberate collisions
  CASE
    WHEN i % 55 = 0 THEN 'SKU-REPEAT'
    ELSE
      upper(substr(w.city, 1, 3)) || '-' ||
      lpad(((h.h1 % 9000) + 1000)::text, 4, '0') || '-' ||
      chr(65 + (h.h2 % 26)::int)
  END,
  -- Single char: letters, with sparse digits / symbols for edge cases
  CASE (h.h3 % 30)
    WHEN 0 THEN (h.h3 % 10)::text
    WHEN 1 THEN '#'
    WHEN 2 THEN '*'
    ELSE chr(65 + (h.h3 % 26)::int)
  END,
  -- Numerics: wide ranges, negatives, zeros, outliers
  CASE
    WHEN i % 111 = 0 THEN 0::smallint
    WHEN i % 97 = 0 THEN (-32768 + (h.h1 % 100))::smallint
    ELSE (((h.h1 % 401) - 200))::smallint
  END,
  CASE
    WHEN i % 119 = 0 THEN 0
    WHEN i % 83 = 0 THEN 2000000000 + (h.h2 % 100000)::int
    ELSE ((h.h2 % 500000) - 100000)::int
  END,
  CASE
    WHEN i % 127 = 0 THEN 0::bigint
    ELSE ((h.h1::bigint * 1000003 + h.h2) % 9007199254740991)
  END,
  (((h.h3 % 1000000) - 200000) + ((h.h1 % 10000)::numeric / 10000.0))::numeric(14, 4),
  (((h.h2 % 20001) - 5000) / 100.0)::real,
  CASE
    WHEN i % 61 = 0 THEN 1e308::double precision
    WHEN i % 67 = 0 THEN (-1e308)::double precision
    WHEN i % 71 = 0 THEN 0::double precision
    ELSE (((h.h1 % 100000) - 25000) + ((h.h3 % 1000)::double precision / 1000.0))
  END,
  CASE
    WHEN i % 17 = 0 THEN NULL
    ELSE (h.h1 % 2 = 0)
  END,
  CASE
    WHEN i % 53 = 0 THEN date '1970-01-01'
    WHEN i % 59 = 0 THEN date '2099-12-31'
    ELSE date '2018-01-01' + ((h.h2 % 2800) || ' days')::interval
  END,
  time '00:00' + (((h.h3 % 86400)) || ' seconds')::interval,
  t.col_timestamp,
  t.col_timestamptz,
  make_interval(
    years => CASE WHEN i % 89 = 0 THEN 1 ELSE 0 END,
    days => h.h1 % 45,
    hours => h.h2 % 24,
    mins => h.h3 % 60,
    secs => (h.h1 % 60)
  ),
  (
    substr(md5('uuid-' || i::text), 1, 8) || '-' ||
    substr(md5('uuid-' || i::text), 9, 4) || '-' ||
    '4' || substr(md5('uuid-' || i::text), 14, 3) || '-' ||
    substr('89ab', 1 + (h.h2 % 4), 1) || substr(md5('uuid-' || i::text), 17, 3) || '-' ||
    substr(md5('uuid-' || i::text), 21, 12)
  )::uuid,
  json_build_object(
    'n', i,
    'title', w.adj || ' ' || w.noun,
    'city', w.city,
    'owner', w.person,
    'note', CASE
      WHEN i % 29 = 0 THEN 'needs review'
      WHEN i % 31 = 0 THEN null
      ELSE 'ok'
    END
  ),
  jsonb_build_object(
    'n', i,
    'region', w.region,
    'status', w.status,
    'priority', 1 + (h.h1 % 5),
    'tags', CASE (h.h2 % 5)
      WHEN 0 THEN '[]'::jsonb
      WHEN 1 THEN jsonb_build_array('demo')
      WHEN 2 THEN jsonb_build_array('demo', 'urgent')
      WHEN 3 THEN jsonb_build_array(w.region, w.status)
      ELSE jsonb_build_array('archive', w.city, 'batch-' || (i % 7))
    END,
    'meta', jsonb_build_object(
      'level', depth.lvl,
      'role', depth.role,
      'sku', upper(substr(w.city, 1, 3)) || '-' || lpad((i % 10000)::text, 4, '0'),
      'active', (h.h3 % 2 = 0)
    )
  ),
  CASE
    WHEN i % 43 = 0 THEN 0::money
    WHEN i % 47 = 0 THEN ((-1 * ((h.h1 % 50000) + 1)) / 100.0)::money
    ELSE ((((h.h2 % 250000) + 1) + ((h.h3 % 100)::numeric / 100.0)))::money
  END,
  decode(lpad(to_hex(h.h1 % 16777216), 8, '0'), 'hex'),
  w.person,
  w.person
FROM generate_series(1, 1000) AS i
CROSS JOIN LATERAL (
  -- plo/phi: allowed parent id range (NULL for roots; L2 skips childless roots 4–5)
  SELECT
    b.lvl,
    b.lo,
    b.hi,
    b.role,
    b.plo,
    b.phi,
    CASE WHEN b.plo IS NULL THEN NULL ELSE b.phi - b.plo + 1 END AS pspan
  FROM (VALUES
    (1,   1,    5, 'org',      NULL::int, NULL::int),
    (2,   6,   50, 'division', 1,         3),
    (3,  51,  200, 'region',   6,        50),
    (4, 201,  500, 'team',    51,       200),
    (5, 501, 1000, 'task',   201,       500)
  ) AS b(lvl, lo, hi, role, plo, phi)
  WHERE i BETWEEN b.lo AND b.hi
) AS depth
CROSS JOIN LATERAL (
  -- md5 hex → non-negative int (via bigint so high bit never overflows int4 cast)
  SELECT
    (('x' || substr(md5(i::text || ':a'), 1, 8))::bit(32)::bigint % 2147483647)::int AS h1,
    (('x' || substr(md5(i::text || ':b'), 1, 8))::bit(32)::bigint % 2147483647)::int AS h2,
    (('x' || substr(md5(i::text || ':c'), 1, 8))::bit(32)::bigint % 2147483647)::int AS h3
) AS h
CROSS JOIN LATERAL (
  SELECT
    (ARRAY[
      'Amber', 'Bright', 'Cedar', 'Copper', 'Crimson', 'Dusk', 'Ember', 'Fern',
      'Golden', 'Harbor', 'Ivory', 'Jade', 'Keen', 'Lunar', 'Maple', 'North',
      'Olive', 'Pearl', 'Quiet', 'River', 'Silver', 'Soft', 'Timber', 'Velvet',
      'Willow', 'Azure', 'Coral', 'Misty', 'Noble', 'Prime', 'Rapid', 'Steady'
    ])[1 + (h.h1 % 32)] AS adj,
    (ARRAY[
      'Anchor', 'Beacon', 'Canvas', 'Cascade', 'Compass', 'Drift', 'Forge', 'Garden',
      'Ledger', 'Market', 'Meadow', 'Mirror', 'Orbit', 'Parcel', 'Quarry', 'Relay',
      'Ridge', 'Signal', 'Summit', 'Transit', 'Valley', 'Vessel', 'Waypoint', 'Workshop',
      'Archive', 'Brief', 'Cluster', 'Dispatch', 'Envelope', 'Fixture', 'Gateway', 'Horizon'
    ])[1 + (h.h2 % 32)] AS noun,
    (ARRAY[
      'Lisbon', 'Oslo', 'Kyoto', 'Denver', 'Cairo', 'Seoul', 'Austin', 'Helsinki',
      'Bogotá', 'Munich', 'Nairobi', 'Quebec', 'Riga', 'Taipei', 'Uppsala', 'Valencia',
      'Warsaw', 'Xiamen', 'Yerevan', 'Zagreb', 'Athens', 'Belfast', 'Cusco', 'Doha',
      'Edinburgh', 'Florence', 'Geneva', 'Havana', 'Istanbul', 'Jakarta', 'Kraków', 'Lyon'
    ])[1 + (h.h3 % 32)] AS city,
    (ARRAY[
      'Ava Nguyen', 'Ben Ortiz', 'Chloe Park', 'Diego Ruiz', 'Elena Berg', 'Farah Ali',
      'Gus Meier', 'Hana Sato', 'Ivan Petrov', 'Jules Moreau', 'Kai Andersen', 'Lina Costa',
      'Marco Rossi', 'Nina Volkov', 'Omar Haddad', 'Priya Shah', 'Quinn Blake', 'Rosa Lima',
      'Sam Okonkwo', 'Tara Singh', 'Uri Cohen', 'Vera Novak', 'Wes Huang', 'Xena Brooks',
      'Yuri Sokolov', 'Zara Khan', 'Amélie Dupont', 'Björn Lind', 'Camille Roux', 'Darius Cole',
      'Eva Nowak', 'Felix Braun'
    ])[1 + ((h.h1 # h.h2) % 32)] AS person,
    (ARRAY['EU', 'US', 'APAC', 'LATAM', 'MEA', 'Nordics', 'ASEAN', 'ANZ'])[1 + (h.h1 % 8)] AS region,
    (ARRAY['draft', 'open', 'in_review', 'blocked', 'done', 'archived'])[1 + (h.h2 % 6)] AS status
) AS w
CROSS JOIN LATERAL (
  SELECT
    (ARRAY[0, 7, 123, 456, 999])[1 + (h.h3 % 5)] AS ms
) AS ms
CROSS JOIN LATERAL (
  SELECT
    timestamp '2020-03-15 09:30:00'
      + ((h.h1 % 2000) * interval '1 day')
      + ((h.h2 % 24) * interval '1 hour')
      + ((h.h3 % 60) * interval '1 minute')
      + (ms.ms || ' milliseconds')::interval AS col_timestamp,
    -- Mixed offsets so absolute UTC sort differs from naive timestamp display.
    (
      to_char(
        timestamp '2020-03-15 09:30:00'
          + ((h.h2 % 2000) * interval '1 day')
          + ((h.h1 % 24) * interval '1 hour')
          + ((h.h3 % 60) * interval '1 minute')
          + (ms.ms || ' milliseconds')::interval,
        'YYYY-MM-DD HH24:MI:SS.MS'
      )
      || CASE (h.h1 % 8)
           WHEN 0 THEN '+00:00'
           WHEN 1 THEN '+03:00'
           WHEN 2 THEN '-05:00'
           WHEN 3 THEN '+09:00'
           WHEN 4 THEN '+05:30'
           WHEN 5 THEN '-08:00'
           WHEN 6 THEN '+01:00'
           ELSE '-03:30'
         END
    )::timestamptz AS col_timestamptz
) AS t;

-- History churn: 3–5 UPDATEs per row (all typed fields reshuffled each time).
-- DEMO-0001: 20 full-field random UPDATEs, then one recent DELETE + re-CREATE.
-- Wait until the clock millisecond advances: history $transactionDate is
-- millisecond-precision, so same-ms events sort ambiguously.
DO $history_seed$
DECLARE
  rec record;
  snap postgresto.demo%ROWTYPE;
  step int;
  steps int;
  cycles int;
  cyc int;
  h1 int;
  h2 int;
  h3 int;
  author text;
  st text;
  prev_ms text;
  child_ids text[];
  authors text[] := ARRAY[
    'Ava Nguyen', 'Ben Ortiz', 'Chloe Park', 'Diego Ruiz', 'Elena Berg',
    'Farah Ali', 'Gus Meier', 'Hana Sato', 'Jules Moreau', 'Kai Andersen',
    'Lina Costa', 'Priya Shah', 'Quinn Blake', 'Rosa Lima', 'Sam Okonkwo'
  ];
  notes text[] := ARRAY[
    'Opened for review',
    'Adjusted pricing',
    'Reassigned owner',
    'Updated region tags',
    'Clarified description',
    'Synced inventory code',
    'Raised priority',
    'Cleared blocker',
    'Linked related site',
    'Refreshed schedule',
    'Normalized currency',
    'Tightened validation',
    'Merged duplicate flags',
    'Published draft notes',
    'Confirmed stakeholder sign-off'
  ];
  statuses text[] := ARRAY[
    'draft', 'open', 'in_review', 'blocked', 'done', 'archived'
  ];
  cities text[] := ARRAY[
    'Lisbon', 'Oslo', 'Kyoto', 'Denver', 'Cairo', 'Seoul', 'Austin', 'Helsinki'
  ];
BEGIN
  FOR rec IN
    SELECT id, text AS title, varchar AS code, parent AS parent_id
    FROM postgresto.demo
    ORDER BY id
  LOOP
    steps := CASE
      WHEN rec.id = 'DEMO-0001' THEN 20
      ELSE 3 + (
        (('x' || substr(md5(rec.id), 1, 8))::bit(32)::bigint % 3)
      )::int
    END;

    FOR step IN 1..steps LOOP
      h1 := (('x' || substr(md5(rec.id || ':u:' || step::text || ':a'), 1, 8))::bit(32)::bigint % 2147483647)::int;
      h2 := (('x' || substr(md5(rec.id || ':u:' || step::text || ':b'), 1, 8))::bit(32)::bigint % 2147483647)::int;
      h3 := (('x' || substr(md5(rec.id || ':u:' || step::text || ':c'), 1, 8))::bit(32)::bigint % 2147483647)::int;
      author := authors[1 + (h1 % array_length(authors, 1))];
      st := statuses[1 + (h2 % array_length(statuses, 1))];

      UPDATE postgresto.demo SET
        text = CASE
          WHEN step = steps THEN rec.title
          ELSE cities[1 + (h3 % array_length(cities, 1))]
            || ' · '
            || notes[1 + (h2 % array_length(notes, 1))]
            || ' #'
            || step::text
        END,
        varchar = 'REV-' || lpad((h1 % 9000 + 1000)::text, 4, '0') || '-' || chr(65 + (h2 % 26)),
        "char" = chr(65 + (h3 % 26)),
        smallint = ((h1 % 401) - 200)::smallint,
        "integer" = (h2 % 500000) - 100000,
        bigint = (h1::bigint * 1000003 + h2) % 9007199254740991,
        numeric = (((h3 % 1000000) - 200000) + ((h1 % 10000)::numeric / 10000.0))::numeric(14, 4),
        real = (((h2 % 20001) - 5000) / 100.0)::real,
        double_precision = ((h1 % 100000) - 25000) + ((h3 % 1000)::double precision / 1000.0),
        boolean = (h1 % 2 = 0),
        date = date '2018-01-01' + ((h2 % 2800) || ' days')::interval,
        time = time '00:00' + ((h3 % 86400) || ' seconds')::interval,
        "timestamp" = timestamp '2020-03-15 09:30:00'
          + ((h1 % 2000) * interval '1 day')
          + ((h2 % 24) * interval '1 hour')
          + ((h3 % 60) * interval '1 minute'),
        timestamptz = (
          to_char(
            timestamp '2020-03-15 09:30:00'
              + ((h2 % 2000) * interval '1 day')
              + ((h1 % 24) * interval '1 hour'),
            'YYYY-MM-DD HH24:MI:SS.MS'
          )
          || CASE (h3 % 4)
               WHEN 0 THEN '+00:00'
               WHEN 1 THEN '+03:00'
               WHEN 2 THEN '-05:00'
               ELSE '+09:00'
             END
        )::timestamptz,
        "interval" = make_interval(
          days => h1 % 45,
          hours => h2 % 24,
          mins => h3 % 60,
          secs => h1 % 60
        ),
        uuid = (
          substr(md5(rec.id || ':u:' || step::text), 1, 8) || '-' ||
          substr(md5(rec.id || ':u:' || step::text), 9, 4) || '-' ||
          '4' || substr(md5(rec.id || ':u:' || step::text), 14, 3) || '-' ||
          substr('89ab', 1 + (h2 % 4), 1) || substr(md5(rec.id || ':u:' || step::text), 17, 3) || '-' ||
          substr(md5(rec.id || ':u:' || step::text), 21, 12)
        )::uuid,
        json = json_build_object(
          'revision', step,
          'note', notes[1 + (h2 % array_length(notes, 1))],
          'city', cities[1 + (h3 % array_length(cities, 1))]
        ),
        jsonb = jsonb_build_object(
          'status', st,
          'revision', step,
          'last_note', notes[1 + (h1 % array_length(notes, 1))],
          'editor', author,
          'priority', 1 + (h2 % 5),
          'tags', jsonb_build_array(st, cities[1 + (h3 % array_length(cities, 1))])
        ),
        money = ((((h2 % 250000) + 1) + ((h3 % 100)::numeric / 100.0)))::money,
        bytea = decode(lpad(to_hex(h1 % 16777216), 8, '0'), 'hex'),
        updated_by = author,
        updated_at = clock_timestamp()
      WHERE id = rec.id;

      prev_ms := to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS');
      LOOP
        EXIT WHEN to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS') <> prev_ms;
      END LOOP;
    END LOOP;
  END LOOP;

  -- DELETE + re-INSERT leaf rows only (parent FK safe). 1–2 cycles each;
  -- standalone roots and a few notable leaves get an extra pass.
  FOR snap IN
    SELECT d.*
    FROM postgresto.demo d
    WHERE NOT EXISTS (
      SELECT 1 FROM postgresto.demo c WHERE c.parent = d.id
    )
    ORDER BY d.id
  LOOP
    cycles := CASE
      WHEN snap.id IN ('DEMO-0004', 'DEMO-0005', 'DEMO-1000') THEN 3
      ELSE 1 + (
        (('x' || substr(md5(snap.id || ':del'), 1, 8))::bit(32)::bigint % 2)
      )::int
    END;

    FOR cyc IN 1..cycles LOOP
      author := authors[1 + ((cyc * 5 + length(snap.id)) % array_length(authors, 1))];

      DELETE FROM postgresto.demo WHERE id = snap.id;
      prev_ms := to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS');
      LOOP
        EXIT WHEN to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS') <> prev_ms;
      END LOOP;

      snap.jsonb := COALESCE(snap.jsonb, '{}'::jsonb)
        || jsonb_build_object(
          'status', 'open',
          'recreated', cyc,
          'last_note', 'Recreated after delete',
          'editor', author
        );
      snap.updated_by := author;
      snap.updated_at := clock_timestamp();
      snap.created_by := COALESCE(snap.created_by, author);

      INSERT INTO postgresto.demo VALUES (snap.*);
      prev_ms := to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS');
      LOOP
        EXIT WHEN to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS') <> prev_ms;
      END LOOP;
    END LOOP;
  END LOOP;

  -- DEMO-0001: one recent DELETE + re-CREATE (detach children for FK, then restore).
  SELECT * INTO snap FROM postgresto.demo WHERE id = 'DEMO-0001';
  IF FOUND THEN
    SELECT coalesce(array_agg(id ORDER BY id), ARRAY[]::text[])
    INTO child_ids
    FROM postgresto.demo
    WHERE parent = 'DEMO-0001';

    author := authors[1 + (length(snap.id) % array_length(authors, 1))];

    UPDATE postgresto.demo
    SET parent = NULL,
        updated_by = author,
        updated_at = clock_timestamp()
    WHERE id = ANY (child_ids);
    prev_ms := to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS');
    LOOP
      EXIT WHEN to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS') <> prev_ms;
    END LOOP;

    DELETE FROM postgresto.demo WHERE id = 'DEMO-0001';
    prev_ms := to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS');
    LOOP
      EXIT WHEN to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS') <> prev_ms;
    END LOOP;

    snap.jsonb := COALESCE(snap.jsonb, '{}'::jsonb)
      || jsonb_build_object(
        'status', 'open',
        'recreated', 1,
        'last_note', 'Recreated after delete',
        'editor', author
      );
    snap.updated_by := author;
    snap.updated_at := clock_timestamp();
    snap.created_by := COALESCE(snap.created_by, author);

    INSERT INTO postgresto.demo VALUES (snap.*);
    prev_ms := to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS');
    LOOP
      EXIT WHEN to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS') <> prev_ms;
    END LOOP;

    UPDATE postgresto.demo
    SET parent = 'DEMO-0001',
        updated_by = author,
        updated_at = clock_timestamp()
    WHERE id = ANY (child_ids);
  END IF;
END
$history_seed$;

-- Fill global search (search) for the freshly seeded demo rows.
SELECT * FROM postgresto.search_refresh('postgresto', 'demo');

NOTIFY pgrst, 'reload schema';
