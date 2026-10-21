# App URLs

App paths are relative to the configured base path (for example, `/postgresto`). Menu links open data views or app pages.

Two namespaces:

| Prefix | For |
| ------ | --- |
| `/data/…` | Postgres tables and SQL views |
| `/pages/…` | Non-data app screens |

## Data — `/data/{schema}/{table}`

`schema` and `table` identify the resource (same idea as `schema.table` on view documents). The path is the **physical / API** table name, not a menu leaf id.

| Path | Role |
| ---- | ---- |
| `/data/{schema}/{table}` | List |
| `/data/{schema}/{table}/record/{id}` | Record page |
| `/data/{schema}/{table}_history` | Standard list for the table's history snapshots |
| `/data/{schema}/{table}/feed` | Feed |
| `/data/{schema}/{table}/columns` | Column selector |
| `/data/{schema}/{table}/stats` | Field stats |
| `/data/{schema}/{table}/fullscreen` | Fullscreen list |

Examples (with base `/postgresto`):

- `http://localhost:7777/postgresto/data/doc/events`
- `http://localhost:7777/postgresto/data/doc/events/record/idofevent`
- [Demo table](http://localhost:7777/postgresto/data/postgresto/demo?offset=0&order=id.asc)

When schema is missing on table meta, the framework schema is used (`postgresto`).

### Views of one table

Views are projections, not separate resources. Same path; differ by `?view=`:

| URL | Meaning |
| --- | ------- |
| `/data/{schema}/{table}` | Bare list → menu-linked view for that table (often Default) |
| `/data/{schema}/{table}?view=demo_tree` | Named saved view |
| `/data/{schema}/{table}?view=Default` | Explicit Default when bare URL means another linked view |

Record and feed pages stay under the source table path. History uses the companion `{table}_history` table as a standard list.

### Menu leaves vs URL

| Concept | Role |
| ------- | ---- |
| View document id (`schema.table\|name`) | Drives `/data/{schema}/{table}` + optional `?view=` |
| Menu leaf `id` | UI identity only (pin, edit, uniqueness) — **not** the URL |
| Several menu leaves → one table | Same `/data/…` path; different `?view=` |

## Pages — `/pages/{name}`

Non-data screens (settings, tools, search, …):

| Path | Screen |
| ---- | ------ |
| `/pages/settings` | Settings hub |
| `/pages/general_settings` | General settings |
| `/pages/menu_manager` | Menu Manager |
| `/pages/view_configurator` | View Configurator |
| `/pages/postgrest_model_extractor` | Alias of View Configurator |
| `/pages/server_info` | Server info (General, DBMS, Auth, Client) |
| `/pages/dbinfo` | Redirects to `/pages/server_info` |
| `/pages/decoder` | Decoder |
| `/pages/json-editor` | JSON Editor |
| `/pages/json-viewer` | JSON Viewer (fullscreen) |
| `/pages/globalsearch` | Global search |
| `/pages/notifications` | Notifications |
| `/pages/about` | About |
| `/pages/profile` | Profile |

Example: `http://localhost:7777/postgresto/pages/decoder`

Menu **path-link** views (`/settings`, `decoder`, …) normalize to `/pages/…`. Links that already start with `/data/` or `/pages/` are left alone.

## Legacy redirects

Flat bookmarks still work and replace-redirect:

- `/{table}` → `/data/{schema}/{table}`
- `/{table}/record/{id}` (and feed / columns / stats / fullscreen) → under `/data/…`
- `/{page}` for known app pages → `/pages/{page}`

## Query params (common)

| Param | Where | Role |
| ----- | ----- | ---- |
| `view` | Data list | Saved view name |
| PostgREST-style filters (`col=eq.…`, `and=(…)`, `or=(…)`) | Data list | Filter builder state (preferred) |
| `filterTree` | Data list | Legacy JSON blob for filters (still parsed; not written) |
| `order`, `offset`, `limit` | Data list | Sort / paging (same names as PostgREST) |
| `quickSearch`, `treeSearch`, `continuous` | Data list | App-only list UI state |
| `id` | Data list | Focused record in the details pane (bare value; not `id=eq.…`) |
| `q` | `/pages/globalsearch` | Search term |

Filter, sort, paging, and search state is serialized into the URL as described below.

## SPA URL vs PostgREST API call

The browser location and the PostgREST request are related but not identical.

| Concern | Browser (SPA) | PostgREST request |
| ------- | ------------- | ----------------- |
| Resource path | `/data/{schema}/{table}` | `{POSTGREST_API_BASE}/{table}` (table only; no `/data/`) |
| Schema | Path segment `{schema}` | Profile header (`Accept-Profile` / `Content-Profile`), not the URL path |
| Saved view | `?view=Name` (app) | Not a query param — loads view doc, then applies its columns/filters/sort |
| Paging | `offset`, `limit` | Same (`offset`, `limit`) |
| Sort | `order=field.asc,…` | Same `order=` |
| Preliminary filter | **Not** in SPA URL (lives on the view doc) | Always AND-merged into the API filter tree |
| Filter pane | PostgREST filter params on the SPA query (`status=eq.open`, `and=(…)`, `or=(…)`) | Same params on the API query (AND with preliminary) |
| Quick search | `quickSearch=term` (app-only) | Expanded to `or=(…ilike…)` / `and=(or(…),or(…))` over searchable columns |
| Tree search | `treeSearch=…` (app-only) | Applied in tree fetch logic; not a PostgREST key of that name |
| Focused row | `id=rowKey` (bare) | Not sent as focus; API may still use `id=eq.…` when filtering by pk |
| Select / count | Not in SPA URL | API adds `select=…`, optional `count=exact` |

## Preliminary filter vs filter pane

Three layers can narrow a list. They stack with **AND** on the PostgREST call.

| Layer | Configured where | Editable in list UI | In SPA URL? | On PostgREST GET? |
| ----- | ---------------- | ------------------- | ----------- | ----------------- |
| **Preliminary filter** | View document `filters.preliminaryFilter` (View Configurator → Filtering) | No — always on for that view | **No** | **Yes** (merged server-side of the UI) |
| **Filter pane** | Session / URL; optional default in view as `filters.filterPane` | Yes — Filter builder sidebar | **Yes** (PostgREST-style params) | **Yes** |
| **Quick search** | Toolbar box; optional default `filters.quickSearch` on the view | Yes | **Yes** (`quickSearch=`) | **Yes** (expanded to `or=` / `and=`) |

### Preliminary filter

- Always-applied base constraints for a **view** (type discriminant, tenant slice, “only active rows”, …).
- Shape: list of `{ field, operator, value }` on the view JSON (`filters.preliminaryFilter`).
- Loaded into table meta at boot / view switch; **not** written into the address bar.
- Users cannot clear them from the filter pane; change them by editing the view (or switching `?view=`).
- Combined with the filter pane as an AND group in the PostgREST request.

### Filter pane

- Interactive Filter builder (`FilterBuilder`): nested AND/OR groups and conditions.
- Applied state is synced to the SPA query string as PostgREST filters (`col=eq.…`, `and=(…)`, `or=(…)`), so reload/share keeps the same pane.
- Saving a named view can persist the current pane as `filters.filterPane` (starting point when that view opens); clearing the pane clears those URL params.
- Does **not** replace preliminary filters — both are sent.

### Effective API filter

```text
API filterTree ≈ AND( preliminaryFilter , filterPane )
                 + quickSearch expansion (extra or=/and=)
```

Example — preliminary on the view, pane in the URL:

```text
View doc:  filters.preliminaryFilter = [{ field: "jsondata->>$type", operator: "eq", value: "Event" }]
SPA:       /postgresto/data/doc/events?status=eq.open
API:       …/events?select=…&and=(jsondata->>$type.eq.Event,status.eq.open)
           + Accept-Profile: doc
```

(Exact representation may be a nested `and=(and(…),…)` depending on serialization; meaning is AND of both layers.)

Example — list with pane filter + sort (no preliminary):

```text
SPA:  /postgresto/data/doc/events?view=Default&offset=0&limit=50&order=id.asc&status=eq.open
API:  {POSTGREST_API_BASE}/events?select=…&limit=50&offset=0&order=id.asc&status=eq.open
      + Accept-Profile: doc
```

Example — quick search (app param → PostgREST `or`):

```text
SPA:  /postgresto/data/postgresto/demo?quickSearch=acme
API:  …/demo?select=…&or=(id.ilike.*acme*,jsondata->>Name.ilike.*acme*,…)
```

## URL length limitations

List state (including filters) is written into the **browser** query string so bookmarks and reload keep the same rows. Large filter trees therefore grow both the SPA URL and the PostgREST GET URL.

Practical limits (nothing enforces these in the app today):

| Layer | Typical ceiling | What happens when exceeded |
| ----- | --------------- | -------------------------- |
| Browsers | ~2–8 KB for the full URL (varies; older IE was ~2 KB) | Address bar / history / sharing break; navigation may fail |
| nginx / reverse proxies | Often **8 KB** default (`large_client_header_buffers`) | **414 URI Too Long** or **400** before PostgREST |
| PostgREST / HTTP stack | Whatever the proxy and server accept | Request rejected; list fails to load |

**Implications**

- Prefer saving a **view** (`?view=Name`) for stable, heavy filter/column setups instead of stuffing a huge **filter pane** into the URL. Put always-on constraints in **preliminary filter** so they do not inflate the address bar.
- Deep nested `and=` / `or=` groups, long `in.(…)` lists, and wide quick-search expansions are the usual blow-ups.
- The API URL can be **longer** than the SPA URL (extra `select=`, quick-search `or=`, **preliminary** filters) even when the address bar looks fine — failures may show up only on the network call.
- There is no automatic switch to POST-RPC or filter truncation when the URL is too long; keep the pane compact or use a saved view.
