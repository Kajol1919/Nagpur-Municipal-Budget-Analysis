# Nagpur Municipal Budget Analysis — PostgreSQL

## Project Purpose
Analyze Nagpur Municipal Corporation budget data using PostgreSQL to compare budgets, departments, revisions, and major budget items.

## Dataset Files
- `data/Dim_Nagpur.csv` — Budget records and financial values.
- `data/Department_Nagpur.csv` — Department code mapping.

## Project Structure
```text
Nagpur_SQL_Project/
├── data/
│   ├── Dim_Nagpur.csv
│   └── Department_Nagpur.csv
├── sql/
│   ├── 01_schema.sql
│   ├── 02_data_loading.sql
│   └── 03_analysis.sql
└── README.md
```

## Requirements
- PostgreSQL


## Run the Project
1. Extract the ZIP file.
2. Create a PostgreSQL database named `nagpur_budget`.
3. Run `sql/01_schema.sql` to create the tables.
4. Run `sql/02_data_loading.sql` to load the CSV data.
5. Run the queries in `sql/03_analysis.sql` to analyze the budget data.


**Note:** Run the data-loading script from the project root folder.