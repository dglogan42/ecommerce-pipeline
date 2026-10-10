# Ecommerce Analytics with dbt and PostgreSQL

A local ecommerce staging pipeline using dbt Core and the dbt-postgres adapter. CSV data is loaded into PostgreSQL's `raw` schema, then transformed into views in `staging` with unique and non-null identifier tests.

## Verified build

The user-reported build on 10 October 2026 completed with:

```text
PASS=21 WARN=0 ERROR=0 SKIP=0 TOTAL=21
```

This covers five ecommerce staging models, two dbt example models, and fourteen identifier tests. These tests do not establish complete business-data correctness or referential integrity.

| Source table | Loaded rows | Staging model |
|---|---:|---|
| raw.customers | 500 | stg_customers |
| raw.products | 80 | stg_products |
| raw.orders | 2,000 | stg_orders |
| raw.order_items | 5,049 | stg_order_items |
| raw.inventory | 80 | stg_inventory |

## Project layout

| Path | Purpose |
|---|---|
| dbt_project.yml | Project name, paths and materializations |
| profiles.yml | Local database credentials; keep out of Git |
| dbt/models/staging/stg_*.sql | Five staging views |
| dbt/models/staging/sources.yml | Definitions for the five raw tables |
| dbt/models/staging/schema.yml | Unique and non-null identifier tests |
| dbt/models/example/ | Optional dbt starter models and tests |
| e commerce/data/*.csv | Input datasets |
| e commerce/sql/schema.sql | Raw-table creation SQL |
| e commerce/src/load_data.py | Optional pandas-based loader |
| e commerce/src/db.py | Optional loader connection helper |

Paths containing `e commerce` must be quoted in shell commands.

## Prerequisites

- A running PostgreSQL server and the `psql` / `createdb` command-line tools.
- Python and an environment containing compatible dbt Core and dbt-postgres versions.
- The project SQL, YAML, schema and CSV files listed above.

The successful run used Python 3.14.4, dbt Core 1.12.5 and dbt-postgres 1.11.0. Preserve a working environment and record its resolved package versions before changing dependencies. These documentation files do not include the application or datasets.

## Configure dbt

The project uses the `ecommerce_dbt` profile, `model-paths: ["dbt/models"]`, and views for the `staging` folder. Set these connection values in your local `profiles.yml`:

```yaml
ecommerce_dbt:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      port: 5432
      user: postgres
      password: "{{ env_var('DBT_POSTGRES_PASSWORD') }}"
      dbname: ecommerce
      schema: staging
      threads: 4
```

For this environment-variable profile, enter the password without saving it in shell history:

```bash
read -rsp 'PostgreSQL password: ' DBT_POSTGRES_PASSWORD
export DBT_POSTGRES_PASSWORD
printf '\n'
```

Alternatively, retain your existing working local profile. Do not publish passwords, `.env` files, or credential-bearing profile backups. A dedicated database role is appropriate for shared deployments.

## Create the database and raw tables

From the project root, for a new database only:

```bash
createdb -h localhost -p 5432 -U postgres -W ecommerce
```

For a new raw schema, apply the supplied table-creation script:

```bash
psql -h localhost -p 5432 -U postgres -d ecommerce -W \
  -v ON_ERROR_STOP=1 -f "e commerce/sql/schema.sql"
```

Inspect the schema script before applying it to a populated database. Verify tables with:

```bash
psql -h localhost -p 5432 -U postgres -d ecommerce -W -c '\dt raw.*'
```

## Load the CSV data without pandas

This replaces the contents of all five raw tables. Keep a backup if the database contains data you need. It uses one transaction; a failed import rolls back the changes when the connection closes. CSV columns must be in the order listed below.

```bash
cd "e commerce/data"
psql -h localhost -p 5432 -U postgres -d ecommerce -W \
  -v ON_ERROR_STOP=1 <<'SQL'
BEGIN;
TRUNCATE TABLE raw.order_items, raw.inventory, raw.orders, raw.products, raw.customers;
\copy raw.customers (customer_id, first_name, last_name, email, city, country, signup_date) FROM 'customers.csv' WITH (FORMAT csv, HEADER true)
\copy raw.products (product_id, product_name, category, price, cost) FROM 'products.csv' WITH (FORMAT csv, HEADER true)
\copy raw.orders (order_id, customer_id, order_date, status) FROM 'orders.csv' WITH (FORMAT csv, HEADER true)
\copy raw.order_items (order_item_id, order_id, product_id, quantity, unit_price) FROM 'order_items.csv' WITH (FORMAT csv, HEADER true)
\copy raw.inventory (product_id, quantity_on_hand, last_updated) FROM 'inventory.csv' WITH (FORMAT csv, HEADER true)
COMMIT;
SQL
cd ../..
```

The original loader's pandas 2.2.2 installation failed to compile under Python 3.14 in this environment. The `psql` workflow above avoids that dependency and uses the existing CSVs directly.

## Build and test

Run from the directory containing `dbt_project.yml` and `profiles.yml`:

```bash
dbt ls --profiles-dir . --resource-type model
dbt debug --profiles-dir . && dbt build --profiles-dir .
```

With examples retained, expect seven models and fourteen tests. With the entire example directory moved outside `dbt/models`, expect five models and ten tests. dbt transforms existing raw tables; it does not load the CSV inputs.

The starter `my_first_dbt_model.sql` should filter its intentionally null ID with:

```sql
select id
from source_data
where id is not null
```

## Troubleshooting

| Symptom | Check |
|---|---|
| Connection refused | Server running; profile port matches its listening port |
| Password authentication failed | Password and user for the selected PostgreSQL server |
| Database ecommerce does not exist | Create it on the same host and port |
| Nothing to do | SQL files under the configured model path |
| Raw relation does not exist | Apply source schema and load CSVs |
| Example not-null test fails | Filter null IDs or archive the example directory |
| Syntax error near null | Use `where id is not null`, not `select id as not null` |

## Scope

This is an ecommerce analytics staging project. It does not implement warehouse stock transactions, shipment clearance, container tracking, or invoices. Inventory tests currently assume one row per product.

## Version control

Exclude local credentials and generated output, for example:

```gitignore
.venv/
.env
.env.*
!.env.example
profiles.yml
profiles.yml.*
target/
logs/
dbt_packages/
__pycache__/
*.pyc
```

Ignore rules do not remove files already tracked by Git. Review tracked files before publishing.

## Licence

Project code is provided under the MIT Licence; see `LICENSE`. Dependencies retain their own licences. Only distribute datasets you have permission to share.
