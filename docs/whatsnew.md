Date: 2026-10-15
- Records: compare two or more selected records side by side; fields that differ from the first selected record are highlighted.

Date: 2026-10-10
- Record details: inspect feed-column records as JSON or open them in a separate tab.
- Records: filter from a selected cell using an operator suited to that field’s type.

Date: 2026-10-08
- DB Info: save snapshots of database reports, label and pin snapshots, and revisit them later.

Date: 2026-10-05
- Search: configure which tables are indexed, enable or disable search per table, and refresh indexes with a progress report.
- Search results: narrow matches by schema and indexed date range.
- Records: use **RAW** to browse a table’s PostgREST fields without the saved view’s field mappings.
- Authentication: inspect the signed-in user’s token claims and OIDC discovery, UserInfo, and JWKS responses.

Date: 2026-10-04
- Trees: two types in View Configurator — **Recursive** (parent pointer, variable depth; Demo Tree) and **Fixed Levels** (was “Fetch per level”). Both need one table/view with all tree columns. See [Trees](framework-tables.md#trees).

Date: 2026-10-02
- Trees: client-only auto fields `Level` / `Path` (show/hide + sort in Field Mapping); footer level counts click to keep branches deep enough (scoped to selected subtree, or whole tree if none selected); hold a count to select/unselect that level, hold longer to select/unselect recursively down. See [Trees](framework-tables.md#trees).

Date: 2026-09-26
- History: changing a record’s primary key logs DELETE of the old id and CREATE of the new id (instead of UPDATE, and instead of skipping when only the id changed).
- Search index: primary-key changes remove the old search id and upsert the new one.
