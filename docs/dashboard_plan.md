# Power BI Dashboard Plan - Diabetes Hospital Readmission

Data folder: `data/powerbi/` (created by `notebooks/05_dashboard_prep.ipynb`)

| File | Rows | One row = | Key columns |
|------|------|-----------|-------------|
| `patients.csv` | 69,970 | one patient (first encounter) | `readmitted_30` (0/1), `age`, `gender`, `race`, `diag_1_group`, `inpatient_band`, `stay_band`, `discharge_disposition`, ... |
| `readmission_by_group.csv` | 84 | one group of one variable | `variable`, `group`, `patients`, `readmitted_30`, `readmission_rate_pct` |
| `model_metrics.csv` | 8 | one model x one metric | `model`, `metric`, `value` |
| `top_features.csv` | 20 | one model x one feature | `model`, `feature`, `value` |

## DAX measures (create on the `patients` table)

```
Patients            = COUNTROWS(patients)
Readmitted 30       = SUM(patients[readmitted_30])
Readmission Rate %  = DIVIDE([Readmitted 30], [Patients]) * 100
Avg Stay (days)     = AVERAGE(patients[time_in_hospital])
```

Use `Readmission Rate %` on every rate chart so the values react to slicers. `readmission_by_group.csv` holds the same rates pre-computed, as a check and as a simple fallback.

**Sort order:** in Power BI, sort `age` alphabetically (already correct: `[0-10)` ... `[90-100)`). For `stay_band` and `inpatient_band`, use "Sort by column" or keep the default text order (already correct).

---

## Page 1 - Overview: "Who is readmitted?"

| # | Visual | Columns used | Purpose |
|---|--------|--------------|---------|
| 1 | Card x 4 | `[Patients]`, `[Readmitted 30]`, `[Readmission Rate %]`, `[Avg Stay (days)]` | Headline numbers (69,970 / 6,277 / 8.97% / 4.24 days on the full data) |
| 2 | Donut chart | Legend: `readmitted`. Values: `[Patients]` | Share of NO / >30 / <30 |
| 3 | Clustered column | Axis: `age`. Values: `[Readmission Rate %]` | Risk rises with age (70-90 highest) |
| 4 | Clustered bar | Axis: `race`. Values: `[Readmission Rate %]`. Tooltip: `[Patients]` | Rate by race |
| 5 | Clustered column | Axis: `gender`. Values: `[Readmission Rate %]` | Rate by gender |
| 6 | Slicers | `gender`, `race`, `age`, `admission_type` | Filter the whole page |

## Page 2 - Clinical Drivers: "What raises the risk?"

| # | Visual | Columns used | Purpose |
|---|--------|--------------|---------|
| 1 | Clustered column | Axis: `inpatient_band`. Values: `[Readmission Rate %]` | Strongest signal: 8.12% (0 visits) to 26.45% (3+) |
| 2 | Line chart | Axis: `time_in_hospital`. Values: `[Readmission Rate %]` | Longer stays mean higher risk |
| 3 | Clustered bar (sorted) | Axis: `diag_1_group`. Values: `[Readmission Rate %]`. Tooltip: `[Patients]` | Injury / Circulatory highest, Respiratory lowest |
| 4 | Clustered bar (Top N = 10 by `[Patients]`) | Axis: `discharge_disposition`. Values: `[Readmission Rate %]` | Discharge to rehab / other inpatient care is high risk |
| 5 | Clustered column | Axis: `A1Cresult`. Legend: `change`. Values: `[Readmission Rate %]` | HbA1c (not significant) and medication change side by side |
| 6 | Matrix | Rows: `diag_1_group`. Columns: `inpatient_band`. Values: `[Readmission Rate %]` with conditional formatting (background color scale) | Heat-map of the two strongest factors combined |
| 7 | Slicers | `age`, `medical_specialty`, `diabetesMed` | Filter the page |

## Page 3 - Model Results: "Can we predict it?"

| # | Visual | Columns used (table) | Purpose |
|---|--------|---------------------|---------|
| 1 | Clustered column | Axis: `metric`. Legend: `model`. Values: `value` (`model_metrics`) | Compare Logistic Regression vs Decision Tree on accuracy, precision, recall, ROC-AUC |
| 2 | Card x 2 | `value` filtered to `metric = roc_auc`, one card per `model` (`model_metrics`) | ROC-AUC 0.646 vs 0.619 |
| 3 | Clustered bar | Axis: `feature`. Values: `value`. Filter: `model = Decision Tree (importance)` (`top_features`) | Top 10 tree features (`number_inpatient` first) |
| 4 | Clustered bar | Axis: `feature`. Values: `value`. Filter: `model = Logistic Regression (coefficient)` (`top_features`) | Top 10 LR coefficients (positive = raises risk) |
| 5 | Text box | - | Key notes: imbalance handled with `class_weight="balanced"`; low precision (~0.13-0.14); large LR coefficients come from rare categories (see notebook 04) |

## Design notes

- One color for "readmitted" (e.g. red) and one for "not readmitted" (e.g. blue) on every page.
- Add the overall rate (8.97%) as a constant line on the rate charts (Analytics pane -> Constant line).
- Page titles as questions ("Who is readmitted?") make the story easy to follow.
