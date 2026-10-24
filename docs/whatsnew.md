2026-10-24
Improvement \ Records Comparator: compare across tables with two-line headers (table + id), column filters that stay visible when nothing matches, resizable columns and rows, and clearer change labels vs the baseline.

2026-10-18
Feature \ History: browse a table’s audit snapshots in a standard list, open individual snapshots, and restore a snapshot or multiple deleted records.

2026-10-18
Feature \ Records: open the history for selected records and follow record links directly from list cells.

2026-10-15
Feature \ Records: compare two or more selected records side by side; fields that differ from the first selected record are highlighted.

2026-10-10
Feature \ Record details: inspect feed-column records as JSON or open them in a separate tab.

2026-10-10
Feature \ Records: filter from a selected cell using an operator suited to that field’s type.

2026-10-08
Feature \ DB Info: save snapshots of database reports, label and pin snapshots, and revisit them later.

2026-10-05
Feature \ Search: configure which tables are indexed, enable or disable search per table, and refresh indexes with a progress report.

2026-10-05
Feature \ Search results: narrow matches by schema and indexed date range.

2026-10-05
Feature \ Records: use **RAW** to browse a table’s PostgREST fields without the saved view’s field mappings.

2026-10-05
Feature \ Authentication: inspect the signed-in user’s token claims and OIDC discovery, UserInfo, and JWKS responses.

2026-10-04
Improvement \ Trees: two types in View Configurator — **Recursive** (parent pointer, variable depth; Demo Tree) and **Fixed Levels** (was “Fetch per level”). Both need one table/view with all tree columns. See [Trees](framework-tables.md#trees).

2026-10-02
Feature \ Trees: client-only auto fields `Level` / `Path` (show/hide + sort in Field Mapping); footer level counts click to keep branches deep enough (scoped to selected subtree, or whole tree if none selected); hold a count to select/unselect that level, hold longer to select/unselect recursively down. See [Trees](framework-tables.md#trees).

2026-09-26
Bugfix \ History: changing a record’s primary key logs DELETE of the old id and CREATE of the new id (instead of UPDATE, and instead of skipping when only the id changed).

2026-09-26
Bugfix \ Search index: primary-key changes remove the old search id and upsert the new one.
