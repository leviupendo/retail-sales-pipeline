# Changes made after review

Every point from the review, what was changed, and how it was verified. All changes were run end to end (load, `dbt seed`, `dbt run` twice, `dbt test`) on a clean Postgres 16.

| # | Review point | Change |
|---|---|---|
| 1 | Post-hook constraints fragile; `WHEN OTHERS THEN NULL` hid failures | Removed hooks. Primary keys are now declared as dbt model contracts (`schema.yml`). Checked that constraints exist after a first and a second run (the hook version left 0 after the second run). |
| 2 | Guests lose their real country; Top Countries chart wrong | `country_name` now on `fct_sales` with FK to new `dim_country`. Test asserts guests keep a real country. |
| 3 | `dim_customer` country arbitrary | Country is now the one on the customer's most recent invoice, ties broken alphabetically (`int_customer_country`). |
| 4 | Staging barely typed | Timestamp parsed once, `customer_id` integer, `unit_price` numeric, description trimmed, `stock_code` trimmed and upper-cased, `is_cancellation` flag. |
| 5 | `dim_date` at invoice-minute grain | Gap-free daily calendar via `dbt_utils.date_spine`; fact joins on `date_key` (YYYYMMDD). Fact keeps `invoice_ts`. |
| 6 | Non-product codes hard-coded and dropped | Moved to seed `non_product_stock_codes.csv` (POST, DOT, C2, M, D, S, B, BANK CHARGES, AMAZONFEE, CRUK) with a category. Rows are kept in the fact and flagged `is_non_product`; `dim_product` has `product_type`/`category`. |
| 7 | Summing duplicates without checking; dedup mixed with aggregation | Separate `int_sales_lines` model; assumption documented; `source_row_count` kept; singular tests for one customer, country and calendar date per line and for price consistency (warn). |
| 8 | Returns via negative quantity | `is_cancellation` uses the `C` invoice prefix; test that cancellations never add stock; warning test lists negative quantities on non-`C` invoices (adjustments). |
| 9 | Thin tests | Not-null + relationships on every fact FK, unique/not-null on every dimension key, accepted values/ranges, row-count and revenue reconciliation tests. 56 tests in total. |
| 10 | Bare, redundantly named source | Source renamed `online_retail`, with table/column descriptions and source tests. |
| 11 | No intermediate layer | `int_sales_lines`, `int_product_descriptions_ranked`, `int_customer_country`. |
| 12 | `load_data.py` not rerunnable, hard-coded paths, float types | Creates the table once, then TRUNCATE + append in one transaction (dependent views survive); CSV path and DB settings from arguments/environment; all columns loaded as text (this fixed CustomerID/UnitPrice landing as floats). Checks row count after load. |
| 13 | Housekeeping | Removed dbt boilerplate and unused config; schemas `staging`/`marts` via a `generate_schema_name` macro; model and column descriptions; `requirements.txt` pinned; README numbers and wording corrected (stale 531,225 row count, inconsistent date range, hooks). |

## Honest notes

- Two earlier pieces of advice in this project were wrong and are now fixed: the post-hook with `WHEN OTHERS THEN NULL` (it failed silently), and dropping postage/adjustments instead of flagging them.
- Several descriptions are lost when `StockCode` casing/whitespace differs; normalising `stock_code` merges those variants.
- Warnings that remain by design: lines with mixed unit prices, negative prices, and negative quantities on non-cancellation invoices.
