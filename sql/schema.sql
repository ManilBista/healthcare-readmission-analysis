-- =====================================================================
-- schema.sql  -  MySQL schema for the Diabetes 130-US Hospitals dataset
-- Run this first:  mysql -u root -p < sql/schema.sql
-- =====================================================================

-- create the database and switch to it
CREATE DATABASE IF NOT EXISTS hospital_readmission;
USE hospital_readmission;

-- drop old tables so the script can be run again
DROP TABLE IF EXISTS encounters;
DROP TABLE IF EXISTS admission_type;
DROP TABLE IF EXISTS discharge_disposition;
DROP TABLE IF EXISTS admission_source;

-- ---------------------------------------------------------------------
-- Lookup tables (from IDS_mapping.csv)
-- ---------------------------------------------------------------------

-- admission type codes, e.g. 1 = Emergency
CREATE TABLE admission_type (
    admission_type_id INT PRIMARY KEY,
    description       VARCHAR(100)
);

-- discharge codes, e.g. 1 = Discharged to home, 11 = Expired
CREATE TABLE discharge_disposition (
    discharge_disposition_id INT PRIMARY KEY,
    description              VARCHAR(150)
);

-- admission source codes, e.g. 7 = Emergency Room
CREATE TABLE admission_source (
    admission_source_id INT PRIMARY KEY,
    description         VARCHAR(100)
);

-- ---------------------------------------------------------------------
-- Main table: one row per hospital encounter (from diabetic_data.csv)
-- "?" values are loaded as NULL by load_data.py
-- Hyphens in medicine names are replaced by underscores
-- ---------------------------------------------------------------------
CREATE TABLE encounters (
    encounter_id             INT PRIMARY KEY,
    patient_nbr              INT NOT NULL,
    race                     VARCHAR(30),
    gender                   VARCHAR(20),
    age                      VARCHAR(10),     -- age band, e.g. '[70-80)'
    weight                   VARCHAR(15),
    admission_type_id        INT,
    discharge_disposition_id INT,
    admission_source_id      INT,
    time_in_hospital         INT,             -- days, 1 to 14
    payer_code               VARCHAR(5),
    medical_specialty        VARCHAR(50),
    num_lab_procedures       INT,
    num_procedures           INT,
    num_medications          INT,
    number_outpatient        INT,             -- visits in the year before
    number_emergency         INT,
    number_inpatient         INT,
    diag_1                   VARCHAR(10),     -- ICD-9 code, primary diagnosis
    diag_2                   VARCHAR(10),
    diag_3                   VARCHAR(10),
    number_diagnoses         INT,
    max_glu_serum            VARCHAR(10),
    A1Cresult                VARCHAR(10),
    -- 23 medicine columns: No / Steady / Up / Down
    metformin                VARCHAR(10),
    repaglinide              VARCHAR(10),
    nateglinide              VARCHAR(10),
    chlorpropamide           VARCHAR(10),
    glimepiride              VARCHAR(10),
    acetohexamide            VARCHAR(10),
    glipizide                VARCHAR(10),
    glyburide                VARCHAR(10),
    tolbutamide              VARCHAR(10),
    pioglitazone             VARCHAR(10),
    rosiglitazone            VARCHAR(10),
    acarbose                 VARCHAR(10),
    miglitol                 VARCHAR(10),
    troglitazone             VARCHAR(10),
    tolazamide               VARCHAR(10),
    examide                  VARCHAR(10),
    citoglipton              VARCHAR(10),
    insulin                  VARCHAR(10),
    glyburide_metformin      VARCHAR(10),
    glipizide_metformin      VARCHAR(10),
    glimepiride_pioglitazone VARCHAR(10),
    metformin_rosiglitazone  VARCHAR(10),
    metformin_pioglitazone   VARCHAR(10),
    `change`                 VARCHAR(5),      -- 'Ch' = medication changed, 'No' = not (CHANGE is a reserved word, so backticks)
    diabetesMed              VARCHAR(5),      -- 'Yes' / 'No'
    readmitted               VARCHAR(5)       -- 'NO', '>30', '<30'
);

-- index on patient number because many queries group by patient
CREATE INDEX idx_patient ON encounters (patient_nbr);
