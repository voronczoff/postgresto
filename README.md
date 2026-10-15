# Postgresto

Postgresto is a configurable data browser \ administration UI for [PostgREST](https://postgrest.org/). It supports relational tables but mainly targeted for document-style tables built around `jsonb`. I got tired of managing scripts in DBeaver, wanted something higher-level, so i came up with this bit of AI slopware to make my life easier.

![Postgresto data browser](docs/images/admin-ui.webp)

## Quickstart

The deployment package includes the prebuilt UI and deployment files. Optionally edit `.env` (the defaults launch with a sample database), then start the Docker Compose stack:

```bash
docker compose up
```

The stack initializes Postgres, applies Liquibase migrations, starts PostgREST, and serves the UI through nginx. Default url: `http://localhost:7777/postgresto/`.

## Features

- **View configuration**
  - Discover database tables and its structure, dig beyond json fields
  - Create mapped table views and hierarchical trees

  ![View configurator for mapping fields and columns](docs/images/saved-views-columns.webp)
  ![Field information and statistics](docs/images/field-info.webp)
  
- **Table views**
  - Browse records with pagination and quick search
  - Filter builder pane
  - Inline field stats and bulk actions
  - Grid edit mode
  - Import and export data in Excel, CSV, JSON and SQL formats
  - Reasonably touchscreen friendly

  ![Filter builder with boolean false and text contains Delta conditions](docs/images/filters.webp)
  ![Inline grid editing](docs/images/table-edit.webp)
  ![Field statistics across the table](docs/images/field-stats-page.webp)
  ![Record details with a JSON field](docs/images/record-details.webp)
  ![Export options](docs/images/csv-export.webp)
  ![Import options](docs/images/csv-import.webp)

- **Hierarchy views**
  - Display recursive or fixed-level tree views.
  - search/filter/filter out control (click the icon to change mode)
  - Level selector and stats

  ![Collapsed navigation with the selected country in its region hierarchy](docs/images/geo-countries.webp)

- **Table history**
  - Configure history tables for selected tables
  - Track inserts, updates, and deletes, with timestamps and user when available
  - Compare versions, with changed fields and their old/new values highlighted
  - Find past changes by table, record, date, or user

- **Global search**
  - PostgreSQL full-text search (`tsvector` / `tsquery`) across selected tables and configured fields
  - JSON search is currently implemented only for the `jsondata` field when its type is `jsonb`
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
  - **DB Info** — useful database queries in one place, including `pg_stat_statements`.
  
  ![DB Info with pg_stat_statements query statistics](docs/images/db-info.webp)

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
