"""
load_data.py

Loads the raw Online Retail CSV into the Postgres landing table
public.raw_online_retail exactly as-is (every column as text, no cleaning).
Typing and cleaning happen later, in dbt.

Safe to re-run: the table is created once and then TRUNCATEd and refilled,
so dbt views that depend on it are never dropped.

Usage:
    python load_data.py                      # uses data.csv and default DB settings
    python load_data.py --csv path/to/data.csv

Settings can also come from environment variables:
    CSV_PATH, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
"""

import argparse
import os

import pandas as pd
from sqlalchemy import create_engine, text

TABLE_NAME = "raw_online_retail"


def parse_args():
    p = argparse.ArgumentParser(description="Load the raw retail CSV into Postgres.")
    p.add_argument("--csv", default=os.getenv("CSV_PATH", "data.csv"))
    p.add_argument("--host", default=os.getenv("DB_HOST", "127.0.0.1"))
    p.add_argument("--port", default=os.getenv("DB_PORT", "5433"))
    p.add_argument("--user", default=os.getenv("DB_USER", "retail_user"))
    p.add_argument("--password", default=os.getenv("DB_PASSWORD", "retail_pass"))
    p.add_argument("--dbname", default=os.getenv("DB_NAME", "retail_sales"))
    return p.parse_args()


def main():
    args = parse_args()

    print(f"Reading {args.csv} ...")
    # dtype=str keeps every value exactly as written (no 17850 -> 17850.0 float
    # surprises); latin1 because the file has non-UTF8 characters.
    df = pd.read_csv(args.csv, encoding="latin1", dtype=str, keep_default_na=False, na_values=[""])
    print(f"Loaded {len(df):,} rows and {len(df.columns)} columns.")

    engine = create_engine(
        f"postgresql+psycopg2://{args.user}:{args.password}@{args.host}:{args.port}/{args.dbname}"
    )

    with engine.begin() as conn:
        # If an older load left typed columns (e.g. CustomerID as float), rebuild the
        # table once so every column is text. Normal re-runs never reach this.
        bad = conn.execute(text(
            "SELECT count(*) FROM information_schema.columns "
            "WHERE table_schema = 'public' AND table_name = :t AND data_type <> 'text'"
        ), {"t": TABLE_NAME}).scalar()
        if bad:
            print("Existing table has non-text columns - rebuilding it once.")
            conn.execute(text(f'DROP TABLE "{TABLE_NAME}" CASCADE'))

        # Create the table (empty) on first run only, then reload it in one transaction.
        df.head(0).to_sql(TABLE_NAME, conn, if_exists="append", index=False)
        conn.execute(text(f'TRUNCATE TABLE "{TABLE_NAME}"'))
        df.to_sql(TABLE_NAME, conn, if_exists="append", index=False, chunksize=10_000, method="multi")
        loaded = conn.execute(text(f'SELECT count(*) FROM "{TABLE_NAME}"')).scalar()

    print(f"Done. {loaded:,} rows in {TABLE_NAME}.")
    if loaded != len(df):
        raise SystemExit("Row count mismatch between CSV and table!")


if __name__ == "__main__":
    main()
