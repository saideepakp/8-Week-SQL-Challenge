SET search_path = data_mart;

-------------------------------------------------------------------------------------------------------------------
---------------------------------------------1. DATA CLEANSING STEPS-----------------------------------------------
-------------------------------------------------------------------------------------------------------------------

/* In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

Convert the week_date to a DATE format

Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

Add a month_number with the calendar month for each week_date value as the 3rd column

Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values

Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

segment	  age_band
1	      Young Adults
2	      Middle Aged
3 or 4	  Retirees
Add a new demographic column using the following mapping for the first letter in the segment values:
segment	  demographic
C	       Couples
F	       Families
Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns

Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record */

CREATE TABLE data_mart.clean_weekly_sales (
    week_date        DATE,
    week_number      INT,
    month_number     INT,
    calendar_year    INT,       
    region           VARCHAR(20),
    platform         VARCHAR(20),
    segment          VARCHAR(10),
    age_band         VARCHAR(20),
    demographic      VARCHAR(20), 
    customer_type    VARCHAR(20),
    transactions     INT,
    sales            BIGINT,
    avg_transaction  DECIMAL(10, 2)
);

INSERT INTO clean_weekly_sales
	WITH converted AS(
		SELECT TO_DATE(week_date, 'DD/MM/YY') AS week_date,
		   	   region,
			   platform,
			   segment,
			   customer_type,
			   transactions,
			   sales
		FROM weekly_sales
	)

	SELECT week_date,
		   CEIL(EXTRACT(DOY FROM week_date) / 7.0) AS week_number,
		   EXTRACT (MONTH FROM week_date) AS month_number,
		   EXTRACT (YEAR FROM week_date) AS calendar_year,
		   region,
		   platform,
		   CASE 
    			WHEN segment = 'null' OR segment IS NULL THEN 'unknown'
    			ELSE segment
				END AS segment,
		   CASE
		   		WHEN segment LIKE '%1' THEN 'Young Adults'
				WHEN segment LIKE '%2' THEN 'Middle Aged'
				WHEN segment LIKE '%3' OR segment LIKE '%4' THEN 'Retirees'
				ELSE 'unknown'
				END AS age_band,
		   CASE
		   		WHEN segment LIKE 'C%' THEN 'Couples'
				WHEN segment LIKE 'F%' THEN 'Families'
				ELSE 'unknown'
				END AS demographic,
		   customer_type,
		   transactions,
		   sales,
		   ROUND((sales::NUMERIC/transactions),2) AS avg_transaction
	  FROM converted;

select * from clean_weekly_sales;

-------------------------------------------------------------------------------------------------------------------
---------------------------------------------2. DATA EXPLORATION---------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
--Question 1: What day of the week is used for each week_date value?

SELECT DISTINCT day_name
FROM(
	SELECT DISTINCT(EXTRACT(DAY FROM week_date)) AS day_date,
	       TO_CHAR(week_date, 'day') AS day_name
	FROM clean_weekly_sales
);

--QUESTION 2: What range of week numbers are missing from the dataset?
SELECT week_number
FROM GENERATE_SERIES(1, 52) AS week_number
WHERE week_number NOT IN (
    SELECT DISTINCT week_number
    FROM clean_weekly_sales
);

--QUESTION 3: How many total transactions were there for each year in the dataset?
SELECT calendar_year, SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year;

--QUESTION 4: What is the total sales for each region for each month?
SELECT region, calendar_year, month_number, TO_CHAR(week_date, 'Mon') AS month_name, SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, calendar_year, month_number, month_name;

--QUESTION 5: What is the total count of transactions for each platform
SELECT platform, SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform;

--QUESTION 6: What is the percentage of sales for Retail vs Shopify for each month?
WITH sales_per_platform AS (
    SELECT 
        SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) AS shopify_sales,
        SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END)  AS retail_sales,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
)
SELECT retail_sales,
       ROUND(100.0 * (retail_sales::NUMERIC / total_sales), 2)  AS retail_percentage,
       shopify_sales,
       ROUND(100.0 * (shopify_sales::NUMERIC / total_sales), 2) AS shopify_percentage
FROM sales_per_platform;

--QUESTION 7: What is the percentage of sales by demographic for each year in the dataset?
WITH sales_by_demographic AS (
    SELECT 
		calendar_year,
        SUM(CASE WHEN demographic = 'Couples' THEN sales ELSE 0 END) AS couples_sales,
        SUM(CASE WHEN demographic = 'Families' THEN sales ELSE 0 END)  AS families_sales,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
	GROUP BY calendar_year
)
SELECT calendar_year, couples_sales,
       ROUND(100.0 * (couples_sales::NUMERIC / total_sales), 2)  AS couples_sales_percentage,
       families_sales,
       ROUND(100.0 * (families_sales::NUMERIC / total_sales), 2) AS families_sales_percentage
FROM sales_by_demographic;

--QUESTION 8: Which age_band and demographic values contribute the most to Retail sales?
SELECT age_band, demographic, SUM(sales) AS total_sales, 
	   ROUND(100.0 * SUM(sales)::NUMERIC / SUM(SUM(sales)) OVER (), 2) AS percentage
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY total_sales DESC;

--QUESTION 9: Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT calendar_year, platform, ROUND(SUM(sales)::NUMERIC / SUM(transactions), 2) AS avg_transaction_size
FROM clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;

-------------------------------------------------------------------------------------------------------------------
---------------------------------------------3. BEFORE & AFTER ANALYSIS--------------------------------------------
-------------------------------------------------------------------------------------------------------------------
/*This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:
*/

SELECT DISTINCT week_date 
FROM clean_weekly_sales
WHERE week_date BETWEEN '2020-06-08' AND '2020-06-15'
ORDER BY week_date;

--QUESTION 1: What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
WITH before_after AS (
    SELECT 
        SUM(CASE WHEN week_date BETWEEN 
            (DATE '2020-06-15' - INTERVAL '4 weeks')
            AND (DATE '2020-06-15' - INTERVAL '1 week')
            THEN sales END) AS before_sales,
        SUM(CASE WHEN week_date BETWEEN 
            DATE '2020-06-15'
            AND (DATE '2020-06-15' + INTERVAL '3 weeks')
            THEN sales END) AS after_sales
    FROM clean_weekly_sales
)
SELECT before_sales, after_sales, after_sales - before_sales AS change,
       ROUND(100.0 * (after_sales - before_sales)::NUMERIC / before_sales, 2) AS percentage_change
FROM before_after;

--QUESTION 2: What about the entire 12 weeks before and after?
WITH before_after AS (
    SELECT 
        SUM(CASE WHEN week_date BETWEEN 
            (DATE '2020-06-15' - INTERVAL '12 weeks')
            AND (DATE '2020-06-15' - INTERVAL '1 week')
            THEN sales END) AS before_sales,
        SUM(CASE WHEN week_date BETWEEN 
            DATE '2020-06-15'
            AND (DATE '2020-06-15' + INTERVAL '11 weeks')
            THEN sales END) AS after_sales
    FROM clean_weekly_sales
)
SELECT before_sales, after_sales, after_sales - before_sales AS change,
       ROUND(100.0 * (after_sales - before_sales)::NUMERIC / before_sales, 2) AS percentage_change
FROM before_after;

--QUESTION 3: How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
--------4 WEEKS COMPARISON
WITH baseline AS (
    SELECT 
        calendar_year,
        MIN(week_date) AS baseline_date
    FROM clean_weekly_sales
    WHERE TO_CHAR(week_date, 'MM-DD') BETWEEN '06-15' AND '06-21'
    GROUP BY calendar_year
),
before_after AS (
    SELECT
        c.calendar_year,
        SUM(CASE 
            WHEN c.week_date BETWEEN 
                (b.baseline_date - INTERVAL '4 weeks')
                AND (b.baseline_date - INTERVAL '1 week')
            THEN sales END) AS before_sales,
        SUM(CASE 
            WHEN c.week_date BETWEEN 
                b.baseline_date
                AND (b.baseline_date + INTERVAL '3 weeks')
            THEN sales END) AS after_sales
    FROM clean_weekly_sales c
    JOIN baseline b ON c.calendar_year = b.calendar_year
    GROUP BY c.calendar_year
)
SELECT calendar_year, before_sales, after_sales, after_sales - before_sales AS change,
    ROUND(100.0 * (after_sales - before_sales)::NUMERIC / before_sales, 2) AS percentage_change
FROM before_after
ORDER BY calendar_year;

--------12 WEEKS COMPARISON
WITH before_after AS (
    SELECT
        calendar_year,
        SUM(CASE 
            WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN '03-23' AND '06-14'
            THEN sales END) AS before_sales,
        SUM(CASE 
            WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN '06-15' AND '09-07'
            THEN sales END) AS after_sales
    FROM clean_weekly_sales
    GROUP BY calendar_year
)
SELECT calendar_year, before_sales, after_sales, after_sales - before_sales AS change,
       ROUND(100.0 * (after_sales - before_sales)::NUMERIC / before_sales, 2) AS percentage_change
FROM before_after
ORDER BY calendar_year;


SELECT DISTINCT 
    calendar_year,
    week_date
FROM clean_weekly_sales
WHERE TO_CHAR(week_date, 'MM-DD') BETWEEN '05-18' AND '07-06'
ORDER BY calendar_year, week_date;

