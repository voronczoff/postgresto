# Liquibase migrations

The Docker Compose deployment runs Liquibase before PostgREST starts. Liquibase creates the fixed `postgresto` framework schema, the configured application schemas, and the tables, functions, triggers, and initial data used by the app.

For an existing database, migrations also move framework documents found in application schemas into `postgresto`. Older installations migrate legacy `model` rows to view documents, remove the obsolete model table, and update menu entries to reference views.

## Migration behavior

| Data | Behavior |
| --- | --- |
| App settings, menu, and default views | Updated from installation defaults during deployment |
| Search table and indexes | Created when missing |
| Demo tables and sample rows | Recreated by the demo data migration |

Product-specific settings and views can be managed in the app. Changes to installation defaults may be applied again by a later deployment.

## Deployment settings

Configure the deployment `.env` file with the database connection values (`PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, and `PGDATABASE`) and `PGSCHEMAS`, a comma-separated list of application schemas. The framework schema `postgresto` is always included. Framework tables have fixed names: `config`, `menu`, `view`, `model`, and `search`.

## Docker Compose

Run `docker compose up` from the deployment package. Postgres starts first, then the migration service, followed by PostgREST and nginx. The app is served on host port **7777**. See the root [README](../README.md).

For a database managed outside this Compose stack, have the database administrator apply the Liquibase migrations supplied with the deployment package before starting the app.
