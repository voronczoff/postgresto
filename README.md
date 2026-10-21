# Postgresto

Postgresto is a configurable data browser \ administration UI for [PostgREST](https://postgrest.org/). It supports relational tables but mainly targeted for document-style tables built around `jsonb`. I got tired of managing scripts in DBeaver, wanted something higher-level, so i came up with this bit of AI slopware to make my life easier.

![Postgresto data browser](docs/images/admin-ui.webp)

## Quickstart

The deployment package includes the prebuilt UI and deployment files. Optionally edit `.env` (the defaults launch with a sample database), then start the Docker Compose stack:

```bash
git clone https://github.com/voronczoff/postgresto
cd postgresto
docker compose up
```

The stack initializes Postgres, applies Liquibase migrations, starts PostgREST, and serves the UI through nginx. Default url: `http://localhost:7777/postgresto/`.

Swagger UI is available at `http://localhost:7777/postgresto/swagger/` by default (`${VITE_BASE_PATH}/swagger` redirects to `${VITE_BASE_PATH}/swagger/`) and loads PostgREST's OpenAPI document from `${VITE_BASE_PATH:-/postgresto}/api`. For a remote deployment, set `PGRST_OPENAPI_SERVER_PROXY_URI` to the public API URL so Swagger's **Try it out** requests use the correct host and path.

Use Swagger UI's schema dropdown to choose `postgresto` or any schema listed in `PGSCHEMAS`. Each selection loads that schema's OpenAPI document and sets the profile headers for **Try it out**, including writes and RPC calls. Restart the Swagger container after changing `PGSCHEMAS`.

## Features

- **View configuration**
  - Discover database tables and its structure, dig beyond json fields
  - Create mapped table views and hierarchical trees
  - JSON fields probing — discover nested fields in up to 1,000 rows, compare them with the current view, and add selected paths.

  ![View configurator for mapping fields and columns](docs/images/saved-views-columns.webp)
  ![JSONB field probing in the demo table](docs/images/json-fields-probing.webp)
  
- **Table views**
  - Browse records with pagination and quick search
  - Filter builder pane
  - Inline field stats and bulk actions
  - Grid edit mode
  - Import and export data in Excel, CSV, JSON and SQL formats
  - Reasonably touchscreen friendly

  ![Filter builder with boolean false and text contains Delta conditions](docs/images/filters.webp)
  ![Inline grid editing](docs/images/table-edit.webp)
  ![Field Info popup for the demo table boolean field](docs/images/field-info.webp)
  ![Field statistics across the table](docs/images/field-stats-page.webp)
  ![Record details with a JSON field](docs/images/record-details.webp)
  ![Export options](docs/images/csv-export.webp)
  ![Import options](docs/images/csv-import.webp)

- **Hierarchy views**
  - Display recursive or fixed-level tree views
  - search/filter/filter out control (click the icon to change mode)
  - Level selector and stats

  ![Collapsed navigation with the selected country in its region hierarchy](docs/images/geo-countries.webp)

- **Table history**
  - Configure history tables for selected tables
  - Track inserts, updates, and deletes, with timestamps and user when available
  - Compare versions, with changed fields and their old/new values highlighted
  - Find past changes by table, record, date, or user
  - History is currently implemented only for changes inside `jsondata` field

- **Global search**
  - PostgreSQL full-text search (`tsvector` / `tsquery`) across selected tables and configured fields
  - Weighted fields, so matches in important fields rank higher
  - Language-aware stemming, phrase search, and boolean operators
  - Relevance ranking with highlighted snippets
  - GIN indexes for speed on large datasets

  ![Global search results with the selected record open in the details pane](docs/images/global-search.webp)

- **Navigation and appearance**
  - Configurable side menu and breadcrumbs
  - Cascading breadcrumb menus for menu sections, views, and hierarchy levels
  - Selectable themes

  ![Breadcrumb menus open over a selected recursive tree record](docs/images/breadcrumbs-menu.webp)
  ![Settings dashboard for navigation and appearance options](docs/images/settings.webp)

- **Additional tools**
  - **JSON Viewer** — inspect JSON in a readable, collapsible tree.
  - **Server info** — General server and build details, DBMS reports including `pg_stat_statements`, Auth diagnostics, and Client browser/device diagnostics.
  
  ![Server info with pg_stat_statements query statistics](docs/images/db-info.webp)

  - **JSON Comparator** — compare two JSON documents with color-coded results for same, different, and missing values. Filter by status or search nested paths. Object key order is ignored; arrays are compared by index.
  - **Decoder** — encode, decode, and convert URL, JSON, XML, YAML, Base64, hex, HTML entities, Unicode escapes, UTF-8/16/32, and binary. It can also decode JWTs and automatically detect input formats.

  ![JSON editor with source and structured tree views](docs/images/json-editor.webp)

- **Authentication:** optionally use OpenID Connect sign-in and PostgREST JWT validation.

## Built with

- [PostgREST](https://postgrest.org/): REST API served straight from the Postgres schema
- [PostgreSQL](https://www.postgresql.org/): storage, JSONB, full-text search
- [Liquibase](https://www.liquibase.com/): schema and seed migrations
- [nginx](https://nginx.org/): serves the UI and proxies the API

## Demo data

The demo geo tables use geographic data from [dr5hn/countries-states-cities-database](https://github.com/dr5hn/countries-states-cities-database) (countries, states, cities). Credit and license terms belong to that project.

## Reference docs

- [App and API URLs](docs/urls.md)
- [Field types](docs/field-types.md)
- [PostgREST setup](docs/postgrest.md)
- [Authentication](docs/authentication.md)
- [Liquibase](docs/liquibase.md)

## Shortcuts

| Context           | Keys  | Action                       |
| ----------------- | ----- | ---------------------------- |
| List              | ← / → | Previous / next page         |
| List              | ↑ / ↓ | First / last page            |
| Record form       | ← / → | Previous / next record       |
| Tree              | ↑ / ↓ | Previous / next visible node |
| Tree record panel | ← / → | Previous / next record       |

Shortcuts are paused while editing inputs or table cells.

For trees - click and hold to select/expand all sublevels.

---

Wishmaking meatbag behind this can be reached here: https://github.com/voronczoff/postgresto
