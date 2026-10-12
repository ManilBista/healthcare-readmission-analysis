-- =====================================================================
-- queries.sql  -  15 analysis queries on the raw encounters table
-- Database: hospital_readmission (MySQL)
-- "Readmission rate" = % of encounters with readmitted = '<30'
-- Pattern used again and again:
--   SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)  -> number readmitted
--   100.0 * that / COUNT(*)                              -> percentage
-- =====================================================================

USE hospital_readmission;


-- Q1. Overall picture: encounters, unique patients, overall <30 day rate
SELECT
    COUNT(*)                                                         AS encounters,
    COUNT(DISTINCT patient_nbr)                                      AS patients,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)              AS readmitted_30,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters;


-- Q2. How many encounters fall in each of the 3 readmitted classes
SELECT
    readmitted,
    COUNT(*)                                       AS encounters,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM encounters), 2) AS pct
FROM encounters
GROUP BY readmitted
ORDER BY encounters DESC;


-- Q3. Readmission rate by age band
SELECT
    age,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters
GROUP BY age
ORDER BY age;


-- Q4. Readmission rate by gender
SELECT
    gender,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters
GROUP BY gender;


-- Q5. Readmission rate by race (NULL = unknown race)
SELECT
    COALESCE(race, 'Unknown') AS race,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters
GROUP BY COALESCE(race, 'Unknown')
ORDER BY encounters DESC;


-- Q6. Readmission rate by time in hospital (days)
SELECT
    time_in_hospital,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters
GROUP BY time_in_hospital
ORDER BY time_in_hospital;


-- Q7. Readmission rate by number of inpatient visits in the year before
--     (3 or more grouped together because those groups are small)
SELECT
    CASE WHEN number_inpatient >= 3 THEN '3+' ELSE CAST(number_inpatient AS CHAR) END AS prior_inpatient,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters
GROUP BY CASE WHEN number_inpatient >= 3 THEN '3+' ELSE CAST(number_inpatient AS CHAR) END
ORDER BY prior_inpatient;


-- Q8. Readmission rate by total prior visits (outpatient + emergency + inpatient)
SELECT
    CASE
        WHEN number_outpatient + number_emergency + number_inpatient = 0 THEN '0 visits'
        WHEN number_outpatient + number_emergency + number_inpatient <= 2 THEN '1-2 visits'
        WHEN number_outpatient + number_emergency + number_inpatient <= 5 THEN '3-5 visits'
        ELSE '6+ visits'
    END AS prior_visits_band,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters
GROUP BY prior_visits_band
ORDER BY prior_visits_band;


-- Q9. Readmission rate by medication change during the stay ('Ch' = changed)
SELECT
    `change`,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters
GROUP BY `change`;


-- Q10. Readmission rate by whether any diabetes medicine was prescribed
SELECT
    diabetesMed,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters
GROUP BY diabetesMed;


-- Q11. Readmission rate by HbA1c test result (NULL = test not done)
SELECT
    COALESCE(A1Cresult, 'Not tested') AS a1c_result,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters
GROUP BY COALESCE(A1Cresult, 'Not tested')
ORDER BY encounters DESC;


-- Q12. Readmission rate by primary diagnosis group
--      ICD-9 ranges follow Strack et al. (2014), the paper that published this dataset
--      Codes starting with V or E are supplementary codes -> 'Other'
SELECT
    CASE
        WHEN diag_1 IS NULL                                             THEN 'Missing'
        WHEN diag_1 LIKE 'V%' OR diag_1 LIKE 'E%'                       THEN 'Other'
        WHEN diag_1 LIKE '250%'                                         THEN 'Diabetes'
        WHEN (CAST(diag_1 AS DECIMAL(6,2)) >= 390 AND CAST(diag_1 AS DECIMAL(6,2)) < 460)
          OR CAST(diag_1 AS DECIMAL(6,2)) = 785                         THEN 'Circulatory'
        WHEN (CAST(diag_1 AS DECIMAL(6,2)) >= 460 AND CAST(diag_1 AS DECIMAL(6,2)) < 520)
          OR CAST(diag_1 AS DECIMAL(6,2)) = 786                         THEN 'Respiratory'
        WHEN (CAST(diag_1 AS DECIMAL(6,2)) >= 520 AND CAST(diag_1 AS DECIMAL(6,2)) < 580)
          OR CAST(diag_1 AS DECIMAL(6,2)) = 787                         THEN 'Digestive'
        WHEN (CAST(diag_1 AS DECIMAL(6,2)) >= 800 AND CAST(diag_1 AS DECIMAL(6,2)) < 1000)           THEN 'Injury'
        WHEN (CAST(diag_1 AS DECIMAL(6,2)) >= 710 AND CAST(diag_1 AS DECIMAL(6,2)) < 740)           THEN 'Musculoskeletal'
        WHEN (CAST(diag_1 AS DECIMAL(6,2)) >= 580 AND CAST(diag_1 AS DECIMAL(6,2)) < 630)
          OR CAST(diag_1 AS DECIMAL(6,2)) = 788                         THEN 'Genitourinary'
        WHEN (CAST(diag_1 AS DECIMAL(6,2)) >= 140 AND CAST(diag_1 AS DECIMAL(6,2)) < 240)           THEN 'Neoplasms'
        ELSE 'Other'
    END AS diagnosis_group,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters
GROUP BY diagnosis_group
ORDER BY readmit_30_pct DESC;


-- Q13. Readmission rate by admission type (JOIN with the lookup table)
SELECT
    t.description AS admission_type,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN e.readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters e
JOIN admission_type t ON e.admission_type_id = t.admission_type_id
GROUP BY t.description
ORDER BY encounters DESC;


-- Q14. Readmission rate by discharge disposition (only groups with 500+ encounters)
--      Shows why expired / hospice patients must be removed later: they cannot be readmitted
SELECT
    d.discharge_disposition_id,
    d.description AS discharged_to,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN e.readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters e
JOIN discharge_disposition d ON e.discharge_disposition_id = d.discharge_disposition_id
GROUP BY d.discharge_disposition_id, d.description
HAVING COUNT(*) >= 500
ORDER BY readmit_30_pct DESC;


-- Q15. Top 10 medical specialties by readmission rate (only specialties with 1000+ encounters)
SELECT
    medical_specialty,
    COUNT(*) AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2) AS readmit_30_pct
FROM encounters
WHERE medical_specialty IS NOT NULL
GROUP BY medical_specialty
HAVING COUNT(*) >= 1000
ORDER BY readmit_30_pct DESC
LIMIT 10;
