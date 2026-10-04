# Retail Sales Analytics Pipeline

A capstone project building a modern data stack pipeline end-to-end: raw CSV → Postgres → dbt (staging + star schema + tests) → Tableau dashboard.

## Dataset

[Online Retail](https://www.kaggle.com/datasets/carrie1/ecommerce-data) — invoice-level transactions from a UK-based online gift retailer, Dec 2010–Dec 2011. 541,909 raw rows, 8 columns.

**Grain statement:** one row = one product (`StockCode`) purchased on one invoice (`InvoiceNo`).

## Tech stack

| Tool | Role |
|---|---|
| Docker (Postgres 16) | Local database, containerized |
| Python (pandas, SQLAlchemy) | Raw CSV ingestion into a landing table |
| dbt (dbt-postgres) | Transformation: staging → star schema, with tests |
| Tableau Public | Dashboard, connected live/extract to Postgres |

## Architecture

```
data.csv
   │  (load_data.py)
   ▼
raw_online_retail        (Postgres landing table, untouched)
   │  (dbt: stg_online_retail.sql)
   ▼
stg_online_retail         (view — renamed columns, light cleanup)
   │  (dbt: marts/*.sql)
   ▼
┌──────────────┬───────────────┬────────────┐
│ dim_product  │ dim_customer  │  dim_date  │
└──────┬───────┴───────┬───────┴─────┬──────┘
       └───────────────┴─────────────┘
                     │
                fct_sales
       (531,225 rows — one row per
        invoice + product line item)
```

## Running it locally

1. `docker compose up -d` — starts Postgres on port 5433
2. `python load_data.py` — loads the raw CSV into `raw_online_retail`
3. `cd retail_dw && dbt run` — builds staging + star schema
4. `dbt test` — runs 8 data quality tests (all passing)
5. Connect Tableau to `127.0.0.1:5433`, database `retail_sales`

## dbt tests

- Grain uniqueness: `invoice_no` + `stock_code` combination is unique in `fct_sales`
- Not-null checks on key columns across all models
- Referential integrity: every `stock_code` in `fct_sales` exists in `dim_product`
- Uniqueness on `dim_product.stock_code` and `dim_customer.customer_id`

Dimension tables also carry Postgres `UNIQUE` constraints (added via dbt post-hooks), which both enforce the grain at the database level and let Tableau's query planner treat joins as many-to-one — this fixed a real performance issue (see below).

## Data quality findings

Several real data issues were found and resolved during this project, not just assumed clean from the source:

- **Duplicate line items**: some invoice/product combinations appeared as many repeated rows of `quantity = 1` instead of one row with the correct total quantity (e.g. one case had 20 identical rows). Fixed by aggregating `fct_sales` with `GROUP BY invoice_no, stock_code` and `SUM(quantity)`.
- **Guest checkouts**: ~25% of line items have no `CustomerID`. Rather than dropping them (which would understate revenue by ~15%), these are mapped to an explicit `customer_id = -1`, `country = 'Unknown'` row in `dim_customer`, so they remain visible and labeled rather than silently excluded.
- **Non-product stock codes**: codes like `POST` (postage), `DOT` (dotcom postage), and `M`/`m` (manual adjustment) are not real products and are excluded from `fct_sales` and `dim_product`.
- **Inconsistent product descriptions**: a given `StockCode` sometimes has several different `Description` values across rows — the real product name, alongside operational notes like "damaged," "check," or blank entries. `dim_product` resolves this by preferring the uppercase, longest description (real product names in this dataset are written in ALL CAPS; operational notes are lowercase), falling back to an explicit `"Unknown Product - <code>"` label when no usable description exists at all.
- **Tableau performance**: without a declared unique constraint on `dim_date.invoice_date`, Tableau's relationship engine assumed a many-to-many join and queries took minutes instead of seconds, despite the same join running in ~60-300ms directly in Postgres. Resolved by adding `UNIQUE` constraints to all three dimension keys.

## Key figures

- 541,909 raw rows → 531,225 rows in `fct_sales` after de-duplication
- Total revenue: ~£9.7M (Dec 2010–Nov 2011 partial year)
- 4,372 unique customers, 4,070 unique products, 38 countries

## Dashboard

Three views: Revenue by Month, Top 10 Products by Revenue, Top 10 Countries by Revenue.
