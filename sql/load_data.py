# load_data.py - load the CSV files into the MySQL tables made by schema.sql
# Run from the project folder:  python sql/load_data.py
# Needs: pip install sqlalchemy pymysql  (already in requirements.txt)

import pandas as pd
import numpy as np
from sqlalchemy import create_engine

# 1. connection string -> change user, password, host if yours are different
DB_URL = "mysql+pymysql://root:password@localhost:3306/hospital_readmission"
engine = create_engine(DB_URL)

# 2. read the main file
df = pd.read_csv("data/diabetic_data.csv")

# 3. "?" means unknown in this file -> turn it into NaN (becomes NULL in MySQL)
df = df.replace("?", np.nan)

# 4. MySQL column names cannot easily have "-", so use "_" instead
df.columns = df.columns.str.replace("-", "_")

# 5. IDS_mapping.csv holds 3 tables stacked on top of each other
#    lines 1-9 = admission type, lines 11-41 = discharge, lines 43-68 = admission source
admission_type = pd.read_csv("data/IDS_mapping.csv", nrows=8)
discharge = pd.read_csv("data/IDS_mapping.csv", skiprows=10, nrows=30)
admission_source = pd.read_csv("data/IDS_mapping.csv", skiprows=42)

# 6. remove extra spaces at the start of some descriptions
admission_source["description"] = admission_source["description"].str.strip()

# 7. write each DataFrame into its table (tables already exist, so append)
admission_type.to_sql("admission_type", engine, if_exists="append", index=False)
discharge.to_sql("discharge_disposition", engine, if_exists="append", index=False)
admission_source.to_sql("admission_source", engine, if_exists="append", index=False)
df.to_sql("encounters", engine, if_exists="append", index=False, chunksize=5000)

# 8. confirm the row counts
print("encounters:", len(df))
print("admission_type:", len(admission_type))
print("discharge_disposition:", len(discharge))
print("admission_source:", len(admission_source))
