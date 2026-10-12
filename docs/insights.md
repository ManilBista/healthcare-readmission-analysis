# Insights - Diabetes Hospital Readmission

Source: `notebooks/03_eda.ipynb`, run on `data/cleaned_readable.csv`  
Population: **69,970 patients** (first encounter per patient, expired/hospice discharges removed)  
Overall 30-day readmission rate: **8.97%** (6,277 patients)

Every number below is printed by the notebook.

## 1. Prior inpatient visits are the strongest signal

| Inpatient visits in the year before | Patients | Readmitted <30 days |
|---|---|---|
| 0 | 61,779 | 8.12% |
| 1 | 5,794 | 12.89% |
| 2 | 1,501 | 18.52% |
| 3+ | 896 | 26.45% |

- The t-test is significant (p ≈ 4.7e-62). Readmitted patients averaged 0.369 prior inpatient visits vs 0.157 for the rest.
- `number_inpatient` has the highest correlation with the target (0.100).

**So what:** patients with 2 or more admissions in the past year should be first in line for discharge follow-up.

## 2. Longer stays carry higher risk

- The rate rises from **6.54%** for 1-day stays to **12.32%** for 8-day stays (12.28%-12.30% at 9-10 days).
- The t-test is significant (p ≈ 2.6e-47). Mean stay was 4.76 days for readmitted vs 4.19 days for the rest.

## 3. Older patients are at higher risk

- Ages 70-80: **10.24%**, ages 80-90: **10.76%** (the highest bands).
- Ages 30-60 sit around 7% (6.98%-7.41%).

## 4. Primary diagnosis matters

- Highest: **Injury 10.78%**, Circulatory 9.67%, Diabetes 9.12%.
- Lowest: **Respiratory 7.28%**, Digestive 8.02%.
- Circulatory is also the largest group (21,383 patients, 31% of all).
- The chi-square test is significant (χ² = 73.7, dof = 8, p ≈ 9.0e-13).

## 5. Medication factors: small but real

- Medication changed during the stay: **9.44%** vs 8.59% not changed (χ² = 15.0, p = 0.0001).
- On diabetes medication: **9.42%** vs 7.55% not on it.

## 6. HbA1c testing showed no significant effect

- Rates: >7 = 8.59%, >8 = 8.16%, Norm = 8.63%, Not tested = 9.10%.
- Chi-square: χ² = 7.27, dof = 3, **p = 0.064 > 0.05**, so not significant.
- 57,125 patients (82%) were never tested, so this result says little about the test itself.

## 7. No single variable separates the groups

- All correlations with the target are weak (max 0.100).
- The scatter and pair plots show readmitted and non-readmitted patients overlapping almost completely.
- **Expectation for modeling:** a model will need many features together, and precision on the positive class will be low.

## Hypothesis test summary (alpha = 0.05)

| # | Test | Variables | Statistic | p-value | Result |
|---|---|---|---|---|---|
| 1 | Chi-square | `change` vs readmitted_30 | χ² = 15.0 | 0.0001 | Significant |
| 2 | Chi-square | `diag_1_group` vs readmitted_30 | χ² = 73.7 | 9.0e-13 | Significant |
| 3 | Chi-square | `A1Cresult` vs readmitted_30 | χ² = 7.27 | 0.064 | Not significant |
| 4 | Welch t-test | `time_in_hospital` | t = 14.55 | 2.6e-47 | Significant |
| 5 | Welch t-test | `number_inpatient` | t = 16.80 | 4.7e-62 | Significant |

**Caution:** with ~70,000 patients even small differences become significant. Effect sizes (the rate gaps above) matter more than p-values.
