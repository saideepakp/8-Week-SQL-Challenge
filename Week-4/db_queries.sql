-----------------------------------------------------------------------------------------------------
--------------------------------------A. Customer Nodes Exploration----------------------------------
-----------------------------------------------------------------------------------------------------
SET search_path TO data_bank;

--Question 1: How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS Unique_nodes
FROM customer_nodes;

--Question 2: What is the number of nodes per region?
SELECT r.region_id, region_name, COUNT(node_id) AS nodes
FROM regions r
JOIN customer_nodes c ON r.region_id = c.region_id
GROUP BY r.region_id, region_name
ORDER BY r.region_id;

--Question 3: How many customers are allocated to each region?
SELECT r.region_id, region_name, COUNT(DISTINCT customer_id) AS customers
FROM regions r
JOIN customer_nodes c ON r.region_id = c.region_id
GROUP BY r.region_id, region_name
ORDER BY r.region_id;

--Question 4: How many days on average are customers reallocated to a different node?
WITH duration_days AS(
	SELECT ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS r_no, 
		   customer_id,
		   node_id,
		   LAG(node_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS prev_node,
		   start_date,
		   end_date, 
		   (end_date - start_date) AS duration
	FROM customer_nodes
),

avg_time AS(
	SELECT customer_id, AVG(duration) AS avg_time
	FROM duration_days
	WHERE EXTRACT(YEAR FROM end_date) != 9999
	GROUP BY customer_id
)

SELECT ROUND(AVG(avg_time),0) AS avg_time_per_customer
FROM avg_time;

--Question 5: What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH duration_days AS (
	SELECT customer_id,
           region_id,
           (end_date - start_date) AS duration
    FROM customer_nodes
    WHERE EXTRACT(YEAR FROM end_date) != 9999
)

SELECT region_id,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY duration) AS median,
       PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY duration) AS percentile_80,
       PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration) AS percentile_95
FROM duration_days
GROUP BY region_id;

-----------------------------------------------------------------------------------------------------
--------------------------------------B. Customer Transactions---------------------------------------
-----------------------------------------------------------------------------------------------------
--Question 1:What is the unique count and total amount for each transaction type?
SELECT txn_type, COUNT(txn_type) AS No_of_txns, SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;

--Question 2:What is the average total historical deposit counts and amounts for all customers?
SELECT ROUND(AVG(no_of_transactions),0) AS avg_transactions, ROUND(AVG(amount),0) AS avg_deposited_amount
FROM (
		SELECT customer_id, COUNT(txn_type) AS no_of_transactions, AVG(txn_amount) AS amount
		FROM customer_transactions
		WHERE txn_type = 'deposit'
		GROUP BY customer_id
		ORDER BY customer_id
)

--Question 3:For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH monthly_transactions AS (
    SELECT 
        customer_id,
        TO_CHAR(txn_date, 'Month') AS month,
        EXTRACT(MONTH FROM txn_date) AS month_no,
        COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
        COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
        COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count
    FROM customer_transactions
    GROUP BY customer_id, TO_CHAR(txn_date, 'Month'), EXTRACT(MONTH FROM txn_date)
)
SELECT 
    month,
    COUNT(DISTINCT customer_id) AS customer_count
FROM monthly_transactions
WHERE deposit_count > 1
AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY month, month_no
ORDER BY month_no;

--Question 4:What is the closing balance for each customer at the end of the month?

WITH monthly_transactions AS (
    SELECT 
        customer_id,
        TO_CHAR(txn_date, 'Month') AS month,
        EXTRACT(MONTH FROM txn_date) AS month_no,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) AS deposit_amount,
        SUM(CASE WHEN txn_type = 'purchase' THEN txn_amount ELSE 0 END) AS purchase_amount,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN txn_amount ELSE 0 END) AS withdrawal_amount
    FROM customer_transactions
    GROUP BY customer_id, TO_CHAR(txn_date, 'Month'), EXTRACT(MONTH FROM txn_date)
)
SELECT 
    customer_id,
    month,
    month_no,
    deposit_amount - (purchase_amount + withdrawal_amount) AS closing_amount
FROM monthly_transactions
ORDER BY customer_id, month_no

--Question 5:What is the percentage of customers who increase their closing balance by more than 5%?
WITH monthly_transactions AS (
    SELECT 
        customer_id,
        TO_CHAR(txn_date, 'Month') AS month,
        EXTRACT(MONTH FROM txn_date) AS month_no,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) AS deposit_amount,
        SUM(CASE WHEN txn_type = 'purchase' THEN txn_amount ELSE 0 END) AS purchase_amount,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN txn_amount ELSE 0 END) AS withdrawal_amount
    FROM customer_transactions
    GROUP BY customer_id, TO_CHAR(txn_date, 'Month'), EXTRACT(MONTH FROM txn_date)
),
closing_balance AS (
    SELECT 
        customer_id,
        month,
        month_no,
        deposit_amount - (purchase_amount + withdrawal_amount) AS monthly_change,
        SUM(deposit_amount - (purchase_amount + withdrawal_amount)) 
            OVER (PARTITION BY customer_id ORDER BY month_no) AS closing_balance
    FROM monthly_transactions
),
pct_change AS (
    SELECT 
        customer_id,
        month,
        month_no,
        closing_balance,
        LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month_no) AS prev_closing_balance,
        ROUND(100.0 * (closing_balance - LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month_no)) 
            / NULLIF(ABS(LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month_no)), 0), 2) AS pct_change
    FROM closing_balance
)
SELECT 
    ROUND(100.0 * COUNT(DISTINCT customer_id) 
        / (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions), 2) AS pct_customers
FROM pct_change
WHERE pct_change > 5;

-----------------------------------------------------------------------------------------------------
--------------------------------------C. Data Allocation Challenge-----------------------------------
-----------------------------------------------------------------------------------------------------
/*To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

Option 1: data is allocated based off the amount of money at the end of the previous month
Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
Option 3: data is updated real-time
For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

running customer balance column that includes the impact each transaction
customer balance at the end of each month
minimum, average and maximum values of the running balance for each customer
Using all of the data available - how much data would have been required for each option on a monthly basis?*/

WITH monthly_transactions AS (
    SELECT 
        customer_id,
        TO_CHAR(txn_date, 'Month') AS month,
        EXTRACT(MONTH FROM txn_date) AS month_no,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) AS deposit_amount,
        SUM(CASE WHEN txn_type = 'purchase' THEN txn_amount ELSE 0 END) AS purchase_amount,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN txn_amount ELSE 0 END) AS withdrawal_amount
    FROM customer_transactions
    GROUP BY customer_id, TO_CHAR(txn_date, 'Month'), EXTRACT(MONTH FROM txn_date)
),
closing_balance AS (
    SELECT 
        customer_id,
        month,
        month_no,
        deposit_amount - (purchase_amount + withdrawal_amount) AS monthly_change,
        SUM(deposit_amount - (purchase_amount + withdrawal_amount)) 
            OVER (PARTITION BY customer_id ORDER BY month_no) AS closing_balance
    FROM monthly_transactions
),

-- Part 1: Running balance per transaction
running_balance AS (
    SELECT 
        customer_id,
        txn_date,
        TO_CHAR(txn_date, 'Month') AS month,
        EXTRACT(MONTH FROM txn_date) AS month_no,
        txn_type,
        txn_amount,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) OVER (PARTITION BY customer_id ORDER BY txn_date) -
        SUM(CASE WHEN txn_type = 'purchase' THEN txn_amount ELSE 0 END) OVER (PARTITION BY customer_id ORDER BY txn_date) -
        SUM(CASE WHEN txn_type = 'withdrawal' THEN txn_amount ELSE 0 END) OVER (PARTITION BY customer_id ORDER BY txn_date) AS running_balance
    FROM customer_transactions
)

-- Part 1: Running balance per transaction
SELECT 
    customer_id,
    txn_date,
    txn_type,
    txn_amount,
    running_balance
FROM running_balance
ORDER BY customer_id, txn_date;

-- Part 2: Closing balance per month
SELECT 
    customer_id,
    month,
    month_no,
    monthly_change,
    closing_balance
FROM closing_balance
ORDER BY customer_id, month_no;

-- Part 3: Min, Avg, Max of running balance
SELECT 
    customer_id,
    MIN(running_balance) AS min_balance,
    ROUND(AVG(running_balance), 2) AS avg_balance,
    MAX(running_balance) AS max_balance
FROM running_balance
GROUP BY customer_id
ORDER BY customer_id;

-- Option 1: Data based on end of previous month balance
WITH prev_month_balance AS (
    SELECT 
        customer_id,
        month,
        month_no,
        LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month_no) AS prev_balance
    FROM closing_balance
)
SELECT 
    month_no,
    month,
    SUM(CASE WHEN prev_balance > 0 THEN prev_balance ELSE 0 END) AS data_required
FROM prev_month_balance
WHERE prev_balance IS NOT NULL
GROUP BY month_no, month
ORDER BY month_no;

-- Option 2: Data based on average balance in previous months
WITH avg_balance AS (
    SELECT
        customer_id,
        month,
        month_no,
        AVG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month_no) AS avg_running_balance
    FROM closing_balance
)
SELECT 
    month_no,
    month,
    SUM(CASE WHEN avg_running_balance > 0 THEN avg_running_balance ELSE 0 END) AS data_required
FROM avg_balance
GROUP BY month_no, month
ORDER BY month_no;

-- Option 3: Data updated real-time
SELECT 
    month_no,
    month,
    SUM(CASE WHEN running_balance > 0 THEN running_balance ELSE 0 END) AS data_required
FROM running_balance
GROUP BY month_no, month
ORDER BY month_no;