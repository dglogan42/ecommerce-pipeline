# Ecommerce pipeline

A local ecommerce staging pipeline using dbt Core and PostgreSQL. CSV data is loaded into the `raw` schema, then built into views in `staging` with unique and non-null identifier tests.

Seed data, the Docker Postgres service, and the Python loader live in [dglogan42/ecommerce](https://github.com/dglogan42/ecommerce). This repository holds the dbt project and an offline Excel workbook module.

## Verified build

The build on 10 October 2026 completed with:

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
| `dbt_project.yml` | Project name, paths, and materializations |
| `profiles.yml` | Local database credentials. Listed in `.gitignore`. Keep passwords out of Git. |
| `dbt/models/staging/stg_*.sql` | Five staging views |
| `dbt/models/staging/sources.yml` | Definitions for the five raw tables |
| `dbt/models/staging/schema.yml` | Unique and non-null identifier tests |
| `dbt/models/example/` | Optional dbt starter models and tests |
| `excel/OfflineExcel.bas` | Offline Excel ADO query and price cleaner |
| `LICENSE` | MIT Licence |

The directory `e commerce` is a gitlink to [dglogan42/ecommerce](https://github.com/dglogan42/ecommerce) at commit `d0bb136`. This repository has no `.gitmodules` entry, so a normal clone does not check out those files. Use the ecommerce repository for the loader and CSVs.

## Prerequisites

- A running PostgreSQL server and the `psql` / `createdb` command-line tools.
- Python and an environment containing compatible dbt Core and dbt-postgres versions.
- The raw tables loaded. Follow the ecommerce repository quick start, or load CSVs with `psql`.

The successful run used Python 3.14.4, dbt Core 1.12.5, and dbt-postgres 1.11.0.

## Configure dbt

The project uses the `ecommerce_dbt` profile, `model-paths: ["dbt/models"]`, and views for the `staging` folder. Create `profiles.yml` in this directory:

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

Enter the password without saving it in shell history:

```bash
read -rsp 'PostgreSQL password: ' DBT_POSTGRES_PASSWORD
export DBT_POSTGRES_PASSWORD
printf '\n'
```

## Load raw tables

From a checkout of [dglogan42/ecommerce](https://github.com/dglogan42/ecommerce), start Postgres and run the loader described in that repository's README.

To load CSVs with `psql` instead, create the database, apply `sql/schema.sql` from that repository, then copy the CSVs into `raw`. Column order:

- `raw.customers`: customer_id, first_name, last_name, email, city, country, signup_date
- `raw.products`: product_id, product_name, category, price, cost
- `raw.orders`: order_id, customer_id, order_date, status
- `raw.order_items`: order_item_id, order_id, product_id, quantity, unit_price
- `raw.inventory`: product_id, quantity_on_hand, last_updated

A `TRUNCATE` of those tables removes rows already stored there.

## Build and test

Run from the directory that contains `dbt_project.yml` and `profiles.yml`:

```bash
dbt ls --profiles-dir . --resource-type model
dbt debug --profiles-dir . && dbt build --profiles-dir .
```

With the example models kept, expect seven models and fourteen tests. With `dbt/models/example` moved aside, expect five models and ten tests. dbt builds views from raw tables. It does not load the CSVs.

`my_first_dbt_model.sql` should filter its intentionally null id:

```sql
select id
from source_data
where id is not null
```

## Offline Excel

`excel/OfflineExcel.bas` is a VBA module for desktop Excel on Windows. Import it in the VBA editor. The ACE OLEDB provider has to match Excel's bitness.

- `QueryExcelAsSQL` reads sheet `Data` (`Product`, `Price`, `Quantity`) through a temp copy of the workbook and writes `Product`, `Price`, `Quantity`, `Total` onto sheet `Results` for rows with `Price > 50`.
- `CleanPricesOffline` reads sheet `Raw` from row 2 (`Product`, `Cost`, `Markup%`). A markup of `20` means 20 percent. It writes the marked-up cost onto sheet `Cleaned`. Blank rows stay blank. Values such as `$1,250.00` are accepted. Prices floor at 0.

## Troubleshooting

| Symptom | Check |
|---|---|
| Connection refused | Server running; profile port matches its listening port |
| Password authentication failed | Password and user for the selected PostgreSQL server |
| Database ecommerce does not exist | Create it on the same host and port |
| Nothing to do | SQL files under the configured model path |
| Raw relation does not exist | Apply the source schema and load the CSVs |
| Example not-null test fails | Filter null ids, or move the example directory aside |
| Syntax error near null | Use `where id is not null` |

## Scope

This is an ecommerce analytics staging project. It does not implement warehouse stock transactions, shipment clearance, container tracking, or invoices. Inventory tests currently assume one row per product.

`.gitignore` excludes `profiles.yml`, `.user.yml`, `target/`, `logs/`, virtualenvs, and `.env` files. Files already committed stay in the repository until they are removed from the index.

## Licence

Project code is released under the MIT Licence. See [LICENSE](LICENSE). Copyright (c) 2026 David Logan. Dependencies retain their own licences.
