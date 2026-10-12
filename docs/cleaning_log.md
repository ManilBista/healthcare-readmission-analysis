# Cleaning Log - Diabetes Hospital Readmission

Notebook: `notebooks/02_cleaning.ipynb`  
Input: `data/diabetic_data.csv` (101,766 rows x 50 columns)  
Outputs:
- `data/cleaned_readable.csv`: 69,970 rows x 51 columns, real units and text labels (for EDA and Power BI)
- `data/cleaned.csv`: 69,970 rows x 140 columns, encoded and scaled (for modeling)

All numbers below come from the notebook output.

| # | Decision | Reason | Effect |
|---|----------|--------|--------|
| 1 | Replace `"?"` with NaN | The file uses `"?"` for unknown values, which pandas does not detect as missing | 7 columns had `"?"`; 0 left after replacing |
| 2 | Drop columns with more than 90% missing | Too little data to be useful; filling 90%+ of a column would be mostly guessing | Dropped `weight` (96.86% missing) and `max_glu_serum` (94.75%). 50 -> 48 columns |
| 3 | Drop columns with only one value | A constant column cannot explain readmission | Dropped `examide` and `citoglipton` (every row = `No`). 48 -> 46 columns |
| 4 | Fill `A1Cresult` NaN with `"Not tested"` | Missing here means the HbA1c test was not done, which is real information | 83.28% of raw rows |
| 5 | Fill `medical_specialty`, `payer_code`, `race` NaN with `"Unknown"` | Too many missing to drop rows (49.08% and 39.56%), and race should never be guessed | Kept as their own category |
| 6 | Keep one encounter per patient (the first, by smallest `encounter_id`) | Repeat visits of the same patient are not independent rows and could leak information between train and test sets. Same choice as the original study (Strack et al. 2014) | 101,766 -> 71,518 rows |
| 7 | Remove discharges coded Expired / Hospice (IDs 11, 13, 14, 19, 20, 21) | These patients cannot be readmitted, so they would bias the model toward "not readmitted" | 1,545 rows removed. 71,518 -> 69,973 |
| 8 | Remove `gender = Unknown/Invalid` | Invalid placeholder value, only 3 rows | 69,973 -> 69,970 rows |
| 9 | Cap outliers at `Q3 + 1.5 * IQR` (upper side only) | Capping keeps every patient but limits the pull of extreme values. Lower limits are 0 or below (nothing flagged), except `number_diagnoses` (1.5), where a value of 1 is a valid patient | `time_in_hospital` capped at 12 (1,403 rows), `num_lab_procedures` at 96 (98), `num_procedures` at 5 (3,845), `num_medications` at 35 (1,867), `number_diagnoses` at 13.5 (42) |
| 10 | Do **not** cap `number_outpatient`, `number_emergency`, `number_inpatient` | Their Q1 = Q3 = 0, so IQR = 0 and the upper limit = 0. Capping would erase every past visit (9,119 / 5,100 / 8,191 rows), the most useful information | Left unchanged |
| 11 | Group ICD-9 codes of `diag_1/2/3` into 9 categories (Circulatory, Respiratory, Digestive, Diabetes, Injury, Musculoskeletal, Genitourinary, Neoplasms, Other) | ~700-800 raw codes per column are too many categories. ICD-9 chapter grouping from Strack et al. 2014. V/E codes and the few missing codes go to `Other` | New `diag_1_group`, `diag_2_group`, `diag_3_group`; raw columns dropped. Largest primary group: Circulatory (21,383 patients) |
| 12 | Keep the 10 most common medical specialties, put the rest in `"Other"` | 71 specialties, most of them rare. One-hot encoding all of them would add many almost-empty columns | 71 -> 12 values (10 + Other + Unknown) |
| 13 | New feature `total_visits` = outpatient + emergency + inpatient | One measure of how much hospital care was needed in the past year | mean 0.56, max 49 |
| 14 | New feature `age_mid` = middle of the age band (`[70-80)` -> 75) | Turns the text band into a number that can be scaled and tested | mean 65.44 |
| 15 | New feature `num_active_meds` = number of the 21 medicines not equal to `No` | How complex the diabetes treatment is | mean 1.19, max 6 |
| 16 | New feature `num_med_changes` = number of medicines with `Up` or `Down` | How much the treatment was adjusted during the stay | mean 0.26, max 4 |
| 17 | Target `readmitted_30` = 1 if `readmitted == "<30"`, else 0 | The project question is early (30-day) readmission | 6,277 positives (8.97%) vs 63,693 (91.03%) |
| 18 | Save `cleaned_readable.csv` before encoding and scaling | EDA charts and Power BI need real units (days, years) and text labels | 69,970 x 51 |
| 19 | Label-encode `gender` (Male = 1), `change` (Ch = 1), `diabetesMed` (Yes = 1) | Only two values each | 0 / 1 columns |
| 20 | Encode the 21 medicine columns as 0 = `No`, 1 = taken (`Steady` / `Up` / `Down`) | One-hot on 21 columns x 4 values would add ~60 mostly-empty columns. The Up / Down direction is already kept in `num_med_changes` | 0 / 1 columns |
| 21 | One-hot encode `race`, `payer_code`, `medical_specialty`, `A1Cresult`, the 3 diagnosis groups, `admission_type_id`, `discharge_disposition_id`, `admission_source_id` (`drop_first=True`) | Categories with no natural order. The ID columns are codes, so they are converted to text first. `drop_first` removes one redundant column per group | 140 columns after encoding |
| 22 | Drop `encounter_id`, `patient_nbr`, `age` (text), `readmitted` (text) from the model file | IDs carry no medical meaning; `age` and `readmitted` were replaced by `age_mid` and `readmitted_30` | Not in `cleaned.csv` (still in `cleaned_readable.csv`) |
| 23 | Standard-scale 12 numeric columns (mean 0, std 1) | Columns have very different ranges, and logistic regression is sensitive to scale. 0/1 columns and the target are not scaled | Verified mean = 0.0, std = 1.0 |

**Known limitation:** the scaler is fit on all 69,970 rows before the train/test split in notebook 04. Mean and standard deviation leak a tiny amount of test-set information. That is accepted here because the task asks for scaling in the cleaning step.
