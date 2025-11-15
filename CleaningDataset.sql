-- -- Data Cleaning -- --

select * from layoffs;

# Data Cleaning Requires :
-- 1. Removing Duplicates
-- 2. Standardize the Data
-- 3. NULL values or blank values - removal or Imputation
-- 4. Remove any columns

# Copying the Raw data so that we never do any blunder with our original data

create table layoff_staging
like layoffs;
# Created the structure

select *
from layoff_staging;

insert layoff_staging select * from layoffs;
# Inserted the data into the new created table layoff_staging

select *,
row_number() over(
partition by company,location,industry, total_laid_off,percentage_laid_off,`date`,stage, country, funds_raised_millions) as row_num
from layoff_staging;

# Now checking is there any duplicate value in this row_num using CTE
with duplicate_cte as 
(
select *,
row_number() over(
partition by company,location,industry, total_laid_off,percentage_laid_off,`date`,stage, country, funds_raised_millions) as row_num
from layoff_staging
)
select * from duplicate_cte 
where row_num>1;

# confirming
select * from layoff_staging
where company='casper';
# yes it has duplicate, confirmed.

# we have to remove the duplicate data and leave only one row of that duplicate data
with duplicate_cte as 
(
select *,
row_number() over(
partition by company,location,industry, total_laid_off,percentage_laid_off,`date`,stage, country, funds_raised_millions) as row_num
from layoff_staging
)
delete 
from duplicate_cte 
where row_num>1;
# this type of deleting (updating a cte) is not accepted in MySQL

-- Creating another table to delete the duplicate rows
# copied the create statement of the layoff_satging table
# after clicking (copy to clipboard -> create statement) on the table
# that's why there is somthing called ENGINE
# added another column row_num INT

CREATE TABLE `layoff_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select * 
from layoff_staging2;

Insert into layoff_staging2
select *,
row_number() over(
partition by company,location,industry, total_laid_off,percentage_laid_off,`date`,stage, country, funds_raised_millions) as row_num
from layoff_staging;

select * from layoff_staging2
where row_num>1;

delete from layoff_staging2
where row_num>1;

# deleted the rows with row_num > 1 (means all duplicates)




-- -- Standardizing Data -- --
# fixing any issues in the data

select company, trim(company) 
from layoff_staging2;

update layoff_staging2 
set company =trim(company);

select distinct industry
from layoff_staging2 order by 1;
# what we found:- 3 industries are like Crypto, CryptoCurrency, Crypto Currency
# All these are same but acting as differect, we have to make them correct

select * 
from layoff_staging2
where industry like 'Crypto%';

update layoff_staging2 
set industry ='Crypto'
where industry like 'Crypto%';

select * 
from layoff_staging2;

select distinct location 
from layoff_staging2 order by 1;
# what we found:- many locations are ending with '...'. And this is invalid name

select distinct location, trim(trailing '.' from location)
from layoff_staging2
order by 1;

update layoff_staging2
set location = trim(trailing '.' from location);

select distinct country
from layoff_staging2 order by 1;
# what we found:- many country names are ending with '...'. And this is invalid name

select distinct country, trim(trailing '.' from country)
from layoff_staging2
order by 1;

update layoff_staging2
set country = trim(trailing '.' from country);




-- -- Our Date column is in text format not in date -- --
# Editing the format of the column

select `date`,
str_to_date(`date`,'%m/%d/%Y')
# capital 'Y'
from layoff_staging2;

update layoff_staging2
set `date`=str_to_date(`date`,'%m/%d/%Y');

# Now data is set to date format, now altering the column
Alter table layoff_staging2
modify column `date` date;

select * from layoff_staging2;

# Handling NULL values

select * from layoff_staging2 
where total_laid_off is null and percentage_laid_off is null;

select * from layoff_staging2 
where industry is null or industry='';

select * from layoff_staging2
where company='Airbnb';

# What I Found: Previously i corrected the names of the location and industry
# That in actual changed so many things in the database
# almost every entry was treted a different one and because of this, we wrote a wrong row_num for that row
# Not Literally wrong but we did not treated it as duplicate. So now making changes, and deleting those new identified duplicates. 
ALTER TABLE layoff_staging2
DROP COLUMN row_num;

CREATE TABLE `layoff_staging3` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` date DEFAULT NULL,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

Insert into layoff_staging3
select *,
row_number() over(
partition by company,location,industry, total_laid_off,percentage_laid_off,`date`,stage, country, funds_raised_millions) as row_num
from layoff_staging2;

select * from layoff_staging3
where row_num>1;

select * from layoff_staging
where country like 'United%' and company='Indigo';

delete from layoff_staging3
where row_num>1;

select * from layoff_staging3
where row_num>1;


# Handling NULL values: Again

select * from layoff_staging3 
where total_laid_off is null and percentage_laid_off is null;

select * from layoff_staging3 
where industry is null or industry='';

select * from layoff_staging3
where company='Airbnb';

# What I Found: Some company's industry is mentioned in some of the rows
# We will do it by JOIN

select t1.industry,t2.industry
from layoff_staging3 t1
join layoff_staging3 t2
	on t1.company=t2.company
where (t1.industry is null or t1.industry='')
and t2.industry is not null;

update layoff_staging3
set industry=null
where industry='';

update layoff_staging3 t1
join layoff_staging3 t2
	on t1.company=t2.company
set t1.industry=t2.industry
where (t1.industry is null)
and t2.industry is not null;

select * from layoff_staging3 
where industry is null or industry='';
# Only one company is now with null industry ie. Bally's Interactive

select * 
from layoff_staging3;

select * from layoff_staging3 
where total_laid_off is null and percentage_laid_off is null;
# we don't know they did laid off or not
# I think we can delete it.
# So I am deleting these rows.

Delete from layoff_staging3
where total_laid_off is null
and percentage_laid_off is null;

# We can't do anything else in this dataset
# So, yes it is not cleaned properly,
Alter table layoff_staging3
drop column row_num;
# 1995 rows are left

select * from layoff_staging3;
