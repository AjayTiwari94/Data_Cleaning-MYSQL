# 📊 Data Analysis Using MySQL - Layoff Dataset

This repository contains the complete end-to-end **Data Cleaning** and **Exploratory Data Analysis (EDA)** workflow performed on a real-world **Layoff Dataset** using **MySQL**. All SQL scripts in this repository were written and executed by Ajay Tiwari.

---

## Repository structure

```
├── CleaningDataset.sql          # Full data cleaning process (duplicates, NULLs, standardization)
├── ExploratoryDataAnlysis.sql   # EDA queries to understand trends and insights
├── layoffs.csv                  # Raw dataset used for the project
├── README.md                    # Project documentation (this file)
└── LICENSE
```

---

## 1. Data Cleaning (`CleaningDataset.sql`)

The cleaning pipeline is implemented step-by-step in **CleaningDataset.sql**. Key steps performed:

- **Create a staging copy** of the raw table to avoid altering original data:
  ```sql
  CREATE TABLE layoff_staging LIKE layoffs;
  INSERT INTO layoff_staging SELECT * FROM layoffs;
  ```

- **Detect & remove duplicates** using `ROW_NUMBER()` window function and intermediate staging tables (`layoff_staging2`, `layoff_staging3`):
  ```sql
  INSERT INTO layoff_staging2
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
  ) AS row_num
  FROM layoff_staging;

  DELETE FROM layoff_staging2 WHERE row_num > 1;
  ```

- **Standardize text fields**:
  - Trim whitespace from `company`, `location`, and `country`
  - Normalize industry values (e.g., `CryptoCurrency`, `Crypto Currency` → `Crypto`)
  - Remove trailing dots from `location` and `country` using `TRIM()`

- **Convert `date` column to proper `DATE` type**:
  ```sql
  UPDATE layoff_staging2
  SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
  ALTER TABLE layoff_staging2 MODIFY COLUMN `date` DATE;
  ```

- **Handle missing/NULL values**:
  - Identify rows where `total_laid_off` and `percentage_laid_off` are NULL and remove them
  - Fill missing `industry` values by joining rows for the same company and copying non-null industry values

- **Final cleaned table**: `layoff_staging3` (1995 records after cleaning in the provided script)

---

## 2. Exploratory Data Analysis (`ExploratoryDataAnlysis.sql`)

All EDA queries are in **ExploratoryDataAnlysis.sql**. Major analyses include:

- **Basic stats**
  ```sql
  SELECT MAX(total_laid_off) FROM layoff_staging3;       -- highest single layoff count (12000)
  SELECT MAX(percentage_laid_off) FROM layoff_staging3;  -- highest percentage (100%)
  ```

- **Top companies by total layoffs**
  ```sql
  SELECT company, SUM(total_laid_off)
  FROM layoff_staging3
  GROUP BY company
  ORDER BY SUM(total_laid_off) DESC;
  ```

- **Industry-wise layoffs**
  ```sql
  SELECT industry, SUM(total_laid_off)
  FROM layoff_staging3
  GROUP BY industry
  ORDER BY 2 DESC;
  ```
  *Finding:* Consumer industry had the highest layoffs (~45,182).

- **Country-wise layoffs**
  ```sql
  SELECT country, SUM(total_laid_off)
  FROM layoff_staging3
  GROUP BY country
  ORDER BY 2 DESC;
  ```
  *Finding:* United States leads (~256,559), India is the second highest.

- **Year-wise & month-wise trends**
  ```sql
  SELECT YEAR(`date`) AS year, SUM(total_laid_off)
  FROM layoff_staging3
  GROUP BY YEAR(`date`);

  SELECT SUBSTRING(`date`, 1, 7) AS month, SUM(total_laid_off)
  FROM layoff_staging3
  GROUP BY month;
  ```
  *Finding:* Peak layoffs in 2022 and 2023 (post-pandemic trends).

- **Stage-wise analysis**
  ```sql
  SELECT stage, SUM(total_laid_off)
  FROM layoff_staging3
  GROUP BY stage;
  ```
  *Finding:* `Post-IPO` stage had the highest layoffs (~204,132).

- **Rolling totals & rankings**
  - Calculated cumulative monthly layoffs using window functions.
  - Used `DENSE_RANK()` per year to extract top 5 companies each year.

---

## How to run locally

1. Create a MySQL database (example: `layoff_db`) and import `layoffs.csv` into a table named `layoffs`.
2. Open MySQL client or MySQL Workbench and run the SQL script `CleaningDataset.sql` step-by-step.
3. After cleaning completes, run `ExploratoryDataAnlysis.sql` to generate analysis outputs.
4. Export query results or visualize using a BI tool (Tableau, Power BI, or Python/R) as needed.

---

## Notes & Remarks

- The SQL scripts use window functions, CTEs, and standard MySQL functions (`ROW_NUMBER()`, `STR_TO_DATE()`, `TRIM()`, `SUBSTRING()`, etc.).
- The cleaning process intentionally preserves the raw `layoffs` table and operates on staging tables to keep reproducibility and safety.
- The README and scripts are authored by Ajay Tiwari. For clarifications, refer to the SQL files or contact the repository owner.

---

## License
This repository is released under the MIT License. See `LICENSE` for details.

**Author:** Ajay Tiwari
B.Tech - Computer Science and Engineering (Artificial Intelligence): 2022-26
