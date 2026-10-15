
# TCGA-BRCA Clinical Survival Analysis

## Project Overview

This project explores clinical data associated with the TCGA-BRCA breast cancer cohort using PostgreSQL and Tableau.

The goal is to demonstrate clinical data validation, SQL-based data preparation, Kaplan–Meier overall-survival estimation, and data visualization.

## Research Question

What are the overall-survival patterns in the available breast cancer clinical cohort, and what data-quality limitations should be considered when interpreting them?

## Tools

- PostgreSQL and pgAdmin
- SQL
- Tableau

## Analysis Workflow

1. Imported clinical patient data into PostgreSQL.
2. Validated patient identifiers and vital-status records.
3. Assessed missing overall-survival times.
4. Prepared a survival-analysis dataset.
5. Calculated Kaplan–Meier survival estimates using SQL.
6. Visualized survival patterns in Tableau.

## Initial Data-Quality Findings

- Source cohort: 817 patient records.
- Records with valid overall-survival times: 816.
- Living/censored records with valid times: 697.
- Deceased records with valid times: 119.
- One deceased record had an unavailable overall-survival time.

## Limitations

This is an exploratory analysis, not a clinical prediction model. Results depend on the completeness and accuracy of the source clinical data, follow-up times, and event coding.

## Project Status

In progress. SQL scripts, validation results, and dashboard screenshots will be added as the analysis develops.

## Data Source

Clinical data associated with the TCGA-BRCA breast cancer cohort. The exact source URL, dataset version, and relevant data-use terms will be documented here.

## Author

Arivarasan Sampathkumar
