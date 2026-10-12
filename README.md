# Hospital Readmission Analysis - Diabetes 130-US Hospitals

**Internship Project 1 of 2** · BSc CSIT, 8th semester (Tribhuvan University)

Which diabetic patients come back to hospital within 30 days of discharge, and can we predict it?
This project cleans ten years of US hospital records (1999-2008), explores what drives early readmission, tests the findings statistically, trains two classification models and prepares the data for a Power BI dashboard.

**Stack:** Python (pandas, NumPy, Matplotlib, Seaborn, SciPy, scikit-learn), MySQL, Git, Power BI

---

## Dataset

- **Name:** Diabetes 130-US Hospitals for Years 1999-2008
- **Source:** UCI Machine Learning Repository: https://archive.ics.uci.edu/dataset/296/diabetes+130-us+hospitals+for+years+1999-2008
- **Files:** `diabetic_data.csv` (101,766 encounters x 50 columns) and `IDS_mapping.csv` (lookup tables for admission type, discharge disposition and admission source)
- **Target:** `readmitted` (`NO`, `>30`, `<30`). This project predicts `<30` (readmitted within 30 days) vs the rest.
- **Paper:** Strack, B. et al. (2014). *Impact of HbA1c Measurement on Hospital Readmission Rates: Analysis of 70,000 Clinical Database Patient Records.* BioMed Research International.

---

## Setup (Windows)

```bash
# 1. go into the project folder
cd healthcare-readmission-analysis

# 2. create and activate a virtual environment
python -m venv venv
venv\Scripts\activate

# 3. install the libraries
pip install -r requirements.txt

# 4. download the dataset zip from the UCI link above and put
#    diabetic_data.csv and IDS_mapping.csv directly inside data/

# 5. open the notebooks and run them in order (01 -> 05)
jupyter notebook
```

**Optional (SQL part):**

```bash
mysql -u root -p < sql/schema.sql      # creates the database and tables
python sql/load_data.py                # edit DB_URL (user/password) at the top first
```

Then run the queries in `sql/queries.sql` in MySQL Workbench.

---

## Folder Structure

```
healthcare-readmission-analysis/
├── data/
│   ├── diabetic_data.csv          # raw data (not in Git, download from UCI)
│   ├── IDS_mapping.csv            # raw lookup tables (not in Git)
│   ├── cleaned_readable.csv       # cleaned, real units + labels (EDA, Power BI)
│   ├── cleaned.csv                # cleaned, encoded + scaled (modeling)
│   ├── model_metrics.csv          # model scores (from notebook 04)
│   ├── top_features.csv           # top 10 features per model (from notebook 04)
│   └── powerbi/                   # tidy CSVs for the dashboard (from notebook 05)
├── notebooks/
│   ├── 01_exploration.ipynb       # first look: shape, types, "?" values, missing, class balance
│   ├── 02_cleaning.ipynb          # cleaning, ICD-9 grouping, new features, encoding, scaling
│   ├── 03_eda.ipynb               # statistics, charts, correlation, hypothesis tests
│   ├── 04_modeling.ipynb          # logistic regression + decision tree
│   └── 05_dashboard_prep.ipynb    # export tidy CSVs for Power BI
├── sql/
│   ├── schema.sql                 # MySQL tables
│   ├── load_data.py               # loads the CSVs into MySQL
│   └── queries.sql                # 15 analysis queries
├── docs/
│   ├── cleaning_log.md            # every cleaning decision and its reason
│   ├── insights.md                # EDA findings and hypothesis tests
│   ├── dashboard_plan.md          # 3-page Power BI plan
│   └── work_log.md                # internship hours
├── requirements.txt
├── .gitignore
└── README.md
```

---

## Process

1. **Exploration:** 101,766 encounters, 50 columns. Unknown values are written as `"?"` in 7 columns; `weight` is 96.86% missing.
2. **SQL:** MySQL schema with lookup tables, plus 15 queries (readmission rate by age, diagnosis, stay length, prior visits, medication change, ...).
3. **Cleaning:** one encounter per patient, expired/hospice discharges removed, outliers capped with IQR, ICD-9 codes grouped into 9 diagnosis groups, 4 new features. Result: **69,970 patients**. Every decision is in `docs/cleaning_log.md`.
4. **EDA:** distributions, readmission rate by group, correlation heatmap, 3 chi-square tests and 2 t-tests.
5. **Modeling:** Logistic Regression and Decision Tree with `class_weight="balanced"` to handle the ~9% / 91% imbalance; 80/20 stratified split.
6. **Dashboard prep:** tidy CSVs and a 3-page Power BI plan.

---

## Key Findings

All numbers come from the notebooks (69,970 patients after cleaning; overall 30-day readmission rate **8.97%**).

1. **Prior inpatient visits are the strongest predictor.** The readmission rate rises from **8.12%** (no prior inpatient visit) to **12.89%** (1), **18.52%** (2) and **26.45%** (3 or more). The decision tree ranks `number_inpatient` as its most important feature (0.319).
2. **Longer stays carry more risk:** 6.54% for a 1-day stay vs about 12% for 8-10 days. Readmitted patients stayed 4.76 days on average vs 4.19 (t-test p ≈ 2.6e-47).
3. **Older patients are at higher risk:** 10.24% (70-80) and 10.76% (80-90), vs about 7% for ages 30-60.
4. **Diagnosis matters:** Injury (10.78%) and Circulatory (9.67%) are highest; Respiratory (7.28%) is lowest (chi-square p ≈ 9.0e-13).
5. **Discharge destination matters:** patients sent to a rehab facility (26.33%) or another inpatient institution (20.59%) come back far more often.
6. **HbA1c result showed no significant link** to 30-day readmission (chi-square p = 0.064).
7. **Readmission is hard to predict from this data:**

| Model | Accuracy | Precision | Recall | ROC-AUC |
|---|---|---|---|---|
| Logistic Regression | 0.658 | 0.139 | 0.540 | **0.646** |
| Decision Tree (max_depth = 5) | 0.610 | 0.128 | 0.575 | 0.619 |

Both models catch more than half of the readmitted patients (always guessing "not readmitted" catches none), but precision is low. Readmission depends on factors not recorded here, such as support at home and follow-up care.

---

## Limitations

- The scaler is fit before the train/test split (the task asks for scaling in the cleaning step), so a tiny amount of test-set information leaks into the model. See `docs/cleaning_log.md`.
- Large logistic regression coefficients for rare categories (e.g. discharge code 15, 40 patients) are unstable and should not be read as main drivers.
- Data is from 1999-2008 US hospitals; patterns may differ today and in other countries.
