"""
load_data.py

Loads the raw Online Retail CSV into a Postgres "landing" table (raw_online_retail),
exactly as-is, with no cleaning or transformation. Cleaning/reshaping happens
later, in dbt.
"""

import pandas as pd
from sqlalchemy import create_engine

# --- 1. Config: where the CSV lives and how to connect to Postgres ---

CSV_PATH = r"C:\Users\hp\OneDrive\Desktop\online commerce\data.csv"

DB_USER = "retail_user"
DB_PASSWORD = "retail_pass"
DB_HOST = "127.0.0.1"
DB_PORT = "5433"
DB_NAME = "retail_sales"

TABLE_NAME = "raw_online_retail"

# --- 2. Read the CSV into a pandas DataFrame ---

print("Reading CSV...")
# encoding="latin1" because this dataset has some non-UTF8 characters
# (common with UK retail product descriptions)
df = pd.read_csv(CSV_PATH, encoding="latin1")

print(f"Loaded {len(df):,} rows and {len(df.columns)} columns from CSV.")
print("Columns:", list(df.columns))

# --- 3. Connect to Postgres ---

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# --- 4. Write the DataFrame into Postgres as a raw landing table ---

print(f"Writing to Postgres table '{TABLE_NAME}'...")
df.to_sql(
    TABLE_NAME,
    engine,
    if_exists="replace",  # drop and recreate the table if it already exists
    index=False,          # don't write pandas' row index as a column
)

print("Done. Data loaded into Postgres.")
