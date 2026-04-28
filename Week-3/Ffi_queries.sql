/* 
customer_id	       plan_id	          start_date
1	                  0	               2020-08-01
1	                  1	               2020-08-08
2	                  0	               2020-09-20
2	                  3	               2020-09-27
11	                  0            	   2020-11-19
11	                  4	               2020-11-26
13	                  0	               2020-12-15
13	                  1	               2020-12-22
13	                  2	               2021-03-29
15	                  0	               2020-03-17
15	                  2	               2020-03-24
15	                  4	               2020-04-29
16	                  0	               2020-05-31
16	                  1	               2020-06-07
16	                  3	               2020-10-21
18	                  0	               2020-07-06
18	                  2	               2020-07-13
19	                  0	               2020-06-22
19	                  2	               2020-06-29
19	                  3	               2020-08-29
*/

-----------------------------------------------------------------------------------------------------
--------------------------------------CUSTOMER JOURNEY-----------------------------------------------
-----------------------------------------------------------------------------------------------------

--QUESTION 1
/*Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier! */

---Every customer chose the free trail before upgrading/downgrading.
---After the completion of free trail, Monthly plans were most opted.
---Out of the 8 customers, only 1 customer had churned. This may prove that the churn rate may be low from the whole dataset.
---Few customers made a second upgrade, in which most of them upgraded to Pro Annual.

-----------------------------------------------------------------------------------------------------
--------------------------------------DATA ANALYSIS QUESTOINS----------------------------------------
-----------------------------------------------------------------------------------------------------

--QUESTION 1: How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS Total_Customers
FROM foodie_fi.subscriptions;

--QUESTION 2: What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
WITH Trail_Plan_by_Month AS(
	SELECT ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_id, start_date ASC) AS r_no,
	       customer_id,
	       plan_id,
	       start_date,
           EXTRACT(MONTH FROM start_date) AS Month_no,
	       TO_CHAR(start_date, 'Mon') AS Month_Name
	FROM foodie_fi.subscriptions
)

SELECT Month_no, Month_Name, COUNT(*) AS No_of_Plans
FROM Trail_Plan_by_Month
WHERE r_no = 1 AND plan_id = 0
GROUP BY Month_no, Month_Name;

--QUESTION 3: What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT plans.plan_id, plan_name, COUNT(*)
FROM foodie_fi.subscriptions
JOIN foodie_fi.plans ON subscriptions.plan_id = plans.plan_id
WHERE EXTRACT(YEAR FROM start_date) > 2020
GROUP BY plans.plan_id, plan_name
ORDER BY plans.plan_id;

--QUESTION 4: What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
WITH churned AS (
	SELECT plan_id, COUNT(DISTINCT customer_id) AS No_of_Customers
	FROM foodie_fi.subscriptions
	WHERE plan_id = 4
	GROUP BY plan_id
)

SELECT No_of_Customers, 
	   ROUND(CAST(No_of_Customers AS DECIMAL(10,3))/ (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions)*100 , 1) AS Percentage_Churned
FROM churned

--QUESTION 5:How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH churned_after_trial AS (
	SELECT ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS r_no, 
	       customer_id, 
		   plan_id
	FROM foodie_fi.subscriptions
	GROUP BY customer_id, plan_id, start_date
)

SELECT COUNT(*) AS No_of_Customers, 
	   ROUND(CAST(COUNT(*) AS DECIMAL(10,3))/ (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions)*100 , 0) AS Percentage_Churned
FROM churned_after_trial
WHERE r_no = 2 AND plan_id = 4

--QUESTION 6: What is the number and percentage of customer plans after their initial free trial?
WITH conversion_after_trial AS (
	SELECT ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS r_no, 
	       customer_id, 
		   plan_id
	FROM foodie_fi.subscriptions
	GROUP BY customer_id, plan_id, start_date
)

SELECT plans.plan_id, 
       plan_name, 
	   COUNT(*) AS No_of_Customers, 
	   ROUND(CAST(COUNT(*) AS DECIMAL(10,3))/ (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions)*100 , 1) AS Percentage_Churned
FROM conversion_after_trial
JOIN foodie_fi.plans ON plans.plan_id = conversion_after_trial.plan_id
WHERE r_no = 2 
GROUP BY plans.plan_id, plan_name
ORDER BY plans.plan_id

--QUESTION 7: What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH all_plans_count AS (
	SELECT ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS r_no, 
	       customer_id, 
		   plan_id,
		   start_date
	FROM foodie_fi.subscriptions
	WHERE start_date <= '2020-12-31' 
	GROUP BY customer_id, plan_id, start_date
)

SELECT plans.plan_id, 
       plan_name, 
	   COUNT(*) AS No_of_Customers, 
	   ROUND(CAST(COUNT(*) AS DECIMAL(10,3))/ (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions)*100 , 1) AS Percentage_Churned
FROM all_plans_count
JOIN foodie_fi.plans ON plans.plan_id = all_plans_count.plan_id
WHERE r_no = 1
GROUP BY plans.plan_id, plan_name
ORDER BY plans.plan_id;

--QUESTION 8: How many customers have upgraded to an annual plan in 2020?
WITH conversion_to_annual AS (
	SELECT ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS r_no, 
	       customer_id, 
		   plan_id
	FROM foodie_fi.subscriptions 
	WHERE EXTRACT(YEAR FROM start_date) = '2020'
	GROUP BY customer_id, plan_id, start_date
)

SELECT plans.plan_id, 
       plan_name, 
	   COUNT(*) AS No_of_Customers
FROM conversion_to_annual
JOIN foodie_fi.plans ON plans.plan_id = conversion_to_annual.plan_id
WHERE r_no != 1 AND plans.plan_id = 3
GROUP BY plans.plan_id, plan_name
ORDER BY plans.plan_id

--QUESTION 9: How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH temp_subscriptions AS(
	SELECT ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) as r_no,
	       customer_id,
	       plan_id,
	       start_date
	FROM foodie_fi.subscriptions
),

enrolled_date AS (
	SELECT customer_id,
		   start_date
	FROM temp_subscriptions
	WHERE r_no = 1
),

enrolled_in_annual_plan_date AS( 
	SELECT customer_id,
	       start_date
	FROM temp_subscriptions
	WHERE plan_id = 3
)

SELECT CAST(AVG(a.start_date - e.start_date) AS INTEGER) AS Avg_time
FROM enrolled_date e
JOIN enrolled_in_annual_plan_date a ON e.customer_id = a.customer_id

--QUESTION 10: Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH temp_subscriptions AS(
    SELECT ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS r_no,
           customer_id,
           plan_id,
           start_date
    FROM foodie_fi.subscriptions
),
enrolled_date AS (
    SELECT customer_id,
           start_date
    FROM temp_subscriptions
    WHERE r_no = 1
),
enrolled_in_annual_plan_date AS( 
    SELECT customer_id,
           start_date
    FROM temp_subscriptions
    WHERE plan_id = 3
)
SELECT 
    (CASE 
        WHEN a.start_date - e.start_date = 0 THEN '0 Days'
        WHEN a.start_date - e.start_date BETWEEN 1 AND 30 THEN '1-30 Days'
        WHEN a.start_date - e.start_date BETWEEN 31 AND 60 THEN '31-60 Days'
        WHEN a.start_date - e.start_date BETWEEN 61 AND 90 THEN '61-90 Days'
        WHEN a.start_date - e.start_date BETWEEN 91 AND 120 THEN '91-120 Days'
        WHEN a.start_date - e.start_date BETWEEN 121 AND 150 THEN '121-150 Days'
        WHEN a.start_date - e.start_date BETWEEN 151 AND 180 THEN '151-180 Days'
        WHEN a.start_date - e.start_date BETWEEN 181 AND 210 THEN '181-210 Days'
        WHEN a.start_date - e.start_date BETWEEN 211 AND 240 THEN '211-240 Days'
        WHEN a.start_date - e.start_date BETWEEN 241 AND 270 THEN '241-270 Days'
        WHEN a.start_date - e.start_date BETWEEN 271 AND 300 THEN '271-300 Days'
        WHEN a.start_date - e.start_date BETWEEN 301 AND 330 THEN '301-330 Days'
        WHEN a.start_date - e.start_date BETWEEN 331 AND 360 THEN '331-360 Days'
        ELSE '360+ Days'
        END) AS Time_taken, 
    COUNT(e.customer_id) AS No_of_Customers
FROM enrolled_date e
JOIN enrolled_in_annual_plan_date a ON e.customer_id = a.customer_id
GROUP BY Time_taken
ORDER BY MIN(a.start_date - e.start_date) ASC

--QUESTION 11: How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH next_plan AS (
    SELECT 
        customer_id,
        plan_id,
        start_date,
        LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan_id,
        LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_start_date
    FROM foodie_fi.subscriptions
)
SELECT COUNT(DISTINCT customer_id) AS downgraded_customers
FROM next_plan
WHERE plan_id = 2                             
AND next_plan_id = 1                          
AND EXTRACT(YEAR FROM next_start_date) = 2020 

