# PostgREST setup

The Docker Compose deployment configures PostgREST from the deployment `.env` file (`PG*` → database connection, `PGSCHEMAS` → exposed application schemas).
`PGRST_DB_SCHEMAS` always starts with `postgresto`, followed by the comma-separated
application schemas from `PGSCHEMAS`.

## JWT auth ON / OFF

Set JWT options in the deployment `.env` file and restart the PostgREST service after changes. Full Keycloak flow: [authentication.md](authentication.md).

**ON** (JWT verified; claim `role` → Postgres role). Default no-token role is **postgres**:

```bash
PGRST_DB_ANON_ROLE=postgres
PGRST_JWT_ROLE_CLAIM_KEY=$.role
PGRST_JWT_SECRET='{"keys":[...]}'   # single-quoted JWKS from Keycloak certs URL
```

- Docker Compose: `PGRST_JWT_SECRET` is **optional** (empty / unset = JWT off). Anon defaults to `postgres`.
- No Bearer → `postgres`. Valid token with `role=authenticated` → `authenticated` role.
- For a locked-down no-token role, set `PGRST_DB_ANON_ROLE=anon` and ensure the `anon` role has the required database permissions.

**OFF** (no JWT verification — lab only):

```bash
PGRST_DB_ANON_ROLE=postgres
# PGRST_JWT_SECRET=
# VITE_OIDC_AUTHORITY=
```

Unset or comment out `PGRST_JWT_SECRET` (and SPA `VITE_OIDC_*` if desired), then
restart PostgREST / Compose. Empty or unset `PGRST_JWT_SECRET` disables JWT
(PostgREST 16+ accepts an empty secret; the official image is scratch-based and
has no shell for an entrypoint wrapper). SPA login gate follows the same
OIDC `.env` values, which nginx passes to the page as meta tags. For other web
servers, configure the equivalent HTML meta tags (see
[authentication.md](authentication.md)).

Equivalent config (for reference):

```ini
db-uri = "postgres://USER:PASS@HOST:5432/DB"
db-schemas = "postgresto, YOUR_SCHEMA_1, YOUR_SCHEMA_2"
db-anon-role = "postgres"
db-aggregates-enabled = true
server-port = 3000
# jwt-secret = '{ "keys": [ ... ] }'   # JWT ON only
# jwt-role-claim-key = "$.role"
```

JSON reads/writes use `Accept: application/vnd.pgrst.array+json;nulls=stripped` so responses omit keys with null values. The UI sends `Accept-Profile` for reads and `Content-Profile` for writes to select a configured application schema.

All framework tables and RPCs live in the fixed `postgresto` schema. Liquibase
persists `PGSCHEMAS` in `postgresto.config`; the Browser and View Configurator
read that runtime config rather than requiring schema names in the UI package.

## History tables

When opening history for a table with API name `apiTable`, the UI requests `{apiTable}_history` in the same schema. Create those tables if you use history features.

Liquibase creates `{table}_history` for framework document tables (`config`, `menu`, `view`) and for `demo`, installs `postgresto.history_log_changes` / `postgresto.update_timestamp` / `postgresto.set_audit_user`, and attaches logging triggers before initial data is inserted. Search (`search`) has no history companion. A primary-key change is logged as DELETE of the old id plus CREATE of the new id.

For other exposed tables, use **Table** in View Configurator (History / Search / Triggers subtabs). It lists on/off switches for `updated_at set` (`postgresto.manage_update_timestamp`), **audit user** (`postgresto.manage_audit_user`), **history log** (`postgresto.manage_history_table`), and **search log** (`postgresto.manage_search_table`). History enable creates the companion table and the `AFTER INSERT OR UPDATE OR DELETE` logging trigger; disable drops the trigger without removing existing snapshots. The caller must have permission to create tables and triggers in the selected schema.

JWT `preferred_username` → `created_by` / `updated_by` is enforced by `postgresto.set_audit_user` (see [authentication.md](authentication.md)). Enable/disable from **Table → Triggers** or `postgresto.manage_audit_user`; Liquibase enables it on all document tables that have both columns.

The live search index trigger is also on **Table → Triggers** (`search log`). Global search allowlist membership and **Refresh index** stay on **Table → Search** (`postgresto.manage_search_table` / `postgresto.search_log_changes` / `postgresto.search_refresh`).

## Schema reload

After DDL changes:

```sql
NOTIFY pgrst, 'reload schema';
```

## CORS

If the UI is served from a different origin than PostgREST, configure CORS on the reverse proxy or PostgREST server accordingly.

## SPA paths vs API

Browser routes (`/data/{schema}/{table}`, filters, `?view=`) and how they map to PostgREST GET URLs (plus URL length limits): [urls.md](urls.md).
