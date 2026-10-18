# Retail Sales Analytics Pipeline

End-to-end pipeline: raw CSV → Postgres (Docker) → dbt (staging → intermediate → star schema, with tests) → Tableau dashboard.

## Dataset

[Online Retail](https://www.kaggle.com/datasets/carrie1/ecommerce-data): invoice lines from a UK online gift retailer, 2010-12-01 to 2011-12-09. 541,909 raw rows, 8 columns.

**Grain of `fct_sales`:** one row per product (`stock_code`) on one invoice (`invoice_no`).

## Architecture

```
data.csv ──(load_data.py)──▶ public.raw_online_retail     all text, untouched
                                   │
                          staging.stg_online_retail       typed + trimmed, no rows removed
                                   │
        staging.int_sales_lines · int_product_descriptions_ranked · int_customer_country
                                   │
   marts: dim_product  dim_customer  dim_country  dim_date  ──▶  fct_sales
```

| Layer | Schema | What it does |
|---|---|---|
| raw | `public` | Landing table, every column as text |
| staging / intermediate | `staging` | Typing, trimming, line aggregation, description ranking |
| marts | `marts` | Star schema with enforced contracts and primary keys |

## Running it

```bash
python -m venv venv && source venv/bin/activate     # Windows: venv\Scripts\activate
pip install -r requirements.txt
docker compose up -d                                  # Postgres on port 5433
python load_data.py --csv data.csv                    # safe to re-run
cp retail_dw/profiles.yml.example ~/.dbt/profiles.yml # Windows: C:\Users\<you>\.dbt\
cd retail_dw
dbt deps && dbt seed && dbt run && dbt test
```

Connect Tableau to `127.0.0.1:5433`, database `retail_sales`, schema `marts`.

## Design decisions

- **Nothing is silently dropped.** Postage, fees and adjustments (`seeds/non_product_stock_codes.csv`) stay in `fct_sales` flagged `is_non_product`; filter them in the dashboard. Guest checkouts (no CustomerID, ~25% of lines) map to `customer_id = -1`.
- **Country lives on the fact** (`country_name` → `dim_country`), so guest sales keep their real country. `dim_customer.country` is the country on the customer's most recent invoice.
- **Repeated rows are summed, not deleted.** When one invoice + product appears on several raw rows (e.g. 20 rows of quantity 1), they are treated as separate scans of the same item. `source_row_count` shows how many rows were folded in, and tests check the assumption (one customer, country and calendar date per line).
- **Cancellations** are invoices whose number starts with `C` (`is_cancellation`). Negative quantity on a non-`C` invoice is a stock adjustment and is reported by a warning test.
- **Product names:** one stock code can have several descriptions. The ALL-CAPS, longest one wins (lower-case ones are notes like "damaged"), ties broken alphabetically.
- **`dim_date`** is a gap-free daily calendar built with `dbt_utils.date_spine`; `fct_sales.date_key` (YYYYMMDD) joins to it.
- **Keys are enforced by dbt model contracts** (primary keys declared in `schema.yml`), not post-hooks, so they are rebuilt correctly on every run.

## Tests

`dbt test` covers: unique/not-null on every dimension key; not-null and relationships on every fact foreign key; fact grain uniqueness; accepted values and ranges; row-count and revenue reconciliation between staging and the fact; consistency of customer, country and calendar date within a line (hard failure), and of timestamp and unit price (warnings); cancellations never adding stock. Price-consistency, timestamp-consistency, negative-price and negative-quantity checks are warnings (known data quirks), the rest are hard failures.

## Known limitations

- A line with several different unit prices shows the lowest in `unit_price`; `revenue` is always exact.
- Some product codes only ever have blank descriptions and appear as `Unknown Product - <code>`.
- Credentials in `docker-compose.yml` are for local development only.
