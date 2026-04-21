------------------------------DATA CLEANING & TRANSFORMATION------------------------------TABLE pr.customer_orders
--TRANSFORMING ALL THE 'null' STRINGS AND NULL VALUES TO BLANK CELLS

UPDATE pizza_runner.customer_orders
SET exclusions = ''
WHERE exclusions = 'null';

UPDATE pizza_runner.customer_orders
SET extras = ''
WHERE extras IS NULL OR extras = 'null';

UPDATE pizza_runner.runner_orders
SET pickup_time = ''
WHERE pickup_time = 'null' OR pickup_time IS NULL;

UPDATE pizza_runner.runner_orders
SET distance = ''
WHERE distance = 'null' OR distance IS NULL;

UPDATE pizza_runner.runner_orders
SET duration = ''
WHERE duration = 'null' OR duration IS NULL;

UPDATE pizza_runner.runner_orders
SET cancellation = ''
WHERE cancellation = 'null' OR cancellation IS NULL;

UPDATE pizza_runner.runner_orders
SET distance = CASE
				WHEN distance LIKE '%km' THEN TRIM(TRAILING 'km' FROM distance) 
				ELSE distance END;

UPDATE pizza_runner.runner_orders
SET duration = CASE
				WHEN duration LIKE '%minutes' THEN TRIM(TRAILING 'minutes' FROM duration)
				WHEN duration LIKE '%mins' THEN TRIM(TRAILING 'mins' FROM duration)
				WHEN duration LIKE '%minute' THEN TRIM(TRAILING 'minute' FROM duration)
				ELSE duration END;

--CHANGING TO CORRECT DATA TYPES

ALTER TABLE pizza_runner.runner_orders
    ALTER COLUMN pickup_time TYPE TIMESTAMP 
        USING NULLIF(pickup_time, '')::TIMESTAMP,
        
    ALTER COLUMN duration TYPE INTEGER 
        USING NULLIF(duration, '')::INTEGER,
        
    ALTER COLUMN distance TYPE FLOAT 
        USING NULLIF(distance, '')::FLOAT;

--TRANSFORMING ALL THE BLANK CELLS TO NULL VALUES (BECAUSE BLANK CELLS ARE INAPPROPRIATE AS THEY CAN"T BE CONSIDERED AS EMPTY)
UPDATE pizza_runner.customer_orders
SET exclusions = NULL
WHERE exclusions = '';

UPDATE pizza_runner.customer_orders
SET extras = NULL
WHERE extras = '';

UPDATE pizza_runner.runner_orders
SET cancellation = NULL
WHERE cancellation = '';
------------------------------------------------------------------------------------------------------------------
---------------------------------------------PIZZA METRICS--------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--QUESTION 1
SELECT COUNT(*)
FROM pizza_runner.customer_orders;

--QUESTION 2
SELECT COUNT(DISTINCT(order_id))
FROM pizza_runner.customer_orders;

--QUESTION 3
SELECT runner_id, COUNT(*)
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

--QUESTION 4
SELECT customer_orders.pizza_id, pizza_name, COUNT(customer_orders.pizza_id) AS "# Delivered"
FROM pizza_runner.customer_orders
JOIN pizza_runner.pizza_names ON customer_orders.pizza_id = pizza_names.pizza_id
JOIN pizza_runner.runner_orders ON customer_orders.order_id = runner_orders.order_id AND cancellation IS NULL
GROUP BY customer_orders.pizza_id, pizza_name;

--QUESTION 5
SELECT customer_id,
	   SUM(CASE
	   		WHEN pizza_id = 1 THEN 1 ELSE 0 END) AS "# of Meatlovers Ordered",
	   SUM(CASE
	   		WHEN pizza_id = 2 THEN 1 ELSE 0 END) AS "# of Vegetarian Ordered"
FROM pizza_runner.customer_orders
GROUP BY customer_id
ORDER BY customer_id;

--QUESTION 6
SELECT order_id, COUNT(pizza_id) AS "# of Pizzas Ordered"
FROM pizza_runner.customer_orders
GROUP BY order_id
ORDER BY "# of Pizzas Ordered" DESC
LIMIT 1;
			   

--QUESTION 7
SELECT customer_id,
		SUM(CASE
				WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 ELSE 0 END) AS "# of Pizzas with Changes"
FROM pizza_runner.customer_orders
JOIN pizza_runner.runner_orders ON customer_orders.order_id = runner_orders.order_id AND cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id;

--QUESTION 8
SELECT COUNT(customer_orders.order_id) AS "# of Pizzas delivered with BOTH Exclusions & extras"
FROM pizza_runner.customer_orders
JOIN pizza_runner.runner_orders ON customer_orders.order_id = runner_orders.order_id AND cancellation IS NULL
WHERE extras IS NOT NULL AND exclusions IS NOT NULL;

--QUESTION 9
SELECT EXTRACT(DAY FROM order_time) AS "Day",
	   TO_CHAR(order_time, 'Day') AS "day_name",
	   EXTRACT(HOUR FROM order_time) AS "Hour",
	   COUNT(order_id) AS "# of Orders"
FROM pizza_runner.customer_orders
GROUP BY "Day","day_name","Hour"
ORDER BY "Day","day_name","Hour";

--QUESTION 10
SELECT EXTRACT(WEEK FROM order_time) AS "Week",
	   EXTRACT(DAY FROM order_time) AS "Day",
	   TO_CHAR(order_time, 'Day') AS "day_name",
	   COUNT(order_id) AS "# of Orders"
FROM pizza_runner.customer_orders
GROUP BY "Week","Day","day_name","Day"
ORDER BY "Week","Day","day_name";



------------------------------------------------------------------------------------------------------------------
------------------------------------------RUNNER & CUSTOMER EXPERIENCE--------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--QUESTION 1
SELECT TO_CHAR(registration_date, 'W') AS "Week", 
COUNT(runner_id) AS "# of Runners Signed up"
FROM pizza_runner.runners
GROUP BY "Week"
ORDER BY "Week";

--QUESTION 2
WITH runner_arrival_time AS (
	SELECT DISTINCT customer_orders.order_id, (pickup_time - order_time) AS arrival_time
	FROM pizza_runner.customer_orders
	JOIN pizza_runner.runner_orders ON customer_orders.order_id = runner_orders.order_id
	WHERE pickup_time IS NOT NULL
)
SELECT  EXTRACT(MINUTE FROM AVG(arrival_time)) AS "Avg Arrival time"
FROM runner_arrival_time;

--QUESTION 3
SELECT customer_orders.order_id, COUNT(customer_orders.order_id) as "# of Pizzas", (pickup_time - order_time) AS Prep_time
FROM pizza_runner.customer_orders
JOIN pizza_runner.runner_orders ON customer_orders.order_id = runner_orders.order_id
WHERE pickup_time IS NOT NULL
GROUP BY customer_orders.order_id, Prep_time
ORDER BY customer_orders.order_id;

--QUESTION 4
SELECT customer_id, CAST(AVG(DISTINCT distance) AS DECIMAL(10,2)) AS "Avg Distance"
FROM pizza_runner.customer_orders
JOIN pizza_runner.runner_orders ON customer_orders.order_id = runner_orders.order_id WHERE distance IS NOT NULL
GROUP BY customer_id
ORDER BY customer_id;

--QUESTION 5
SELECT (MAX(duration) - MIN(duration)) AS difference
FROM pizza_runner.runner_orders;

--QUESTION 6
SELECT distinct customer_id, (customer_orders.order_id) as ordersid, runner_id, CAST((((distance)/(duration))*60) AS DECIMAL(10,2)) AS "Avg_Speed_in_Kmph"
FROM pizza_runner.runner_orders
JOIN pizza_runner.customer_orders ON runner_orders.order_id = customer_orders.order_id and distance IS NOT NULL and duration IS NOT NULL
order BY customer_id,customer_orders.order_id,runner_id;

--QUESTION 7
SELECT runner_id,
	   CONCAT((CAST(SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) AS FLOAT)/COUNT(order_id))*100,'%')  AS "Success_Rate"
FROM pizza_runner.runner_orders
GROUP BY runner_id
ORDER BY runner_id;


------------------------------------------------------------------------------------------------------------------
------------------------------------------INGREDIENT OPTIMIZATION--------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--QUESTION 1
SELECT pizza_id, topping_name
FROM pizza_runner.pizza_recipes
CROSS JOIN UNNEST(
    STRING_TO_ARRAY(toppings, ', ')
) AS recipe_topping_id                                       
JOIN pizza_runner.pizza_toppings 
    ON CAST(recipe_topping_id AS INT) = pizza_toppings.topping_id   
ORDER BY pizza_id, topping_name;

--QUESTION 2
WITH toppings_added AS (
    SELECT 
        customer_id, 
        pizza_id,
        extras_added
    FROM pizza_runner.customer_orders
    LEFT JOIN LATERAL UNNEST(
        STRING_TO_ARRAY(extras, ', ')
    ) AS extras_added ON TRUE
)
SELECT DISTINCT(extras_added), topping_name, COUNT(extras_added)
FROM toppings_added
JOIN pizza_runner.pizza_toppings ON CAST(toppings_added.extras_added AS INT) = pizza_toppings.topping_id
WHERE extras_added IS NOT NULL
GROUP BY extras_added, topping_name
ORDER BY extras_added;

--QUESTION 3
WITH toppings_removed AS (
    SELECT 
        customer_id, 
        pizza_id,
        exclusions_made
    FROM pizza_runner.customer_orders
    LEFT JOIN LATERAL UNNEST(
        STRING_TO_ARRAY(exclusions, ', ')
    ) AS exclusions_made ON TRUE
)
SELECT DISTINCT(exclusions_made), topping_name, COUNT(exclusions_made)
FROM toppings_removed
JOIN pizza_runner.pizza_toppings ON CAST(toppings_removed.exclusions_made AS INT) = pizza_toppings.topping_id
WHERE exclusions_made IS NOT NULL
GROUP BY exclusions_made, topping_name
ORDER BY exclusions_made;

--QUESTION 4
WITH orderitems AS (
    SELECT ROW_NUMBER() OVER (ORDER BY order_id) AS row_id,  -- unique ID for each row
           order_id, 
           customer_id, 
           customer_orders.pizza_id, 
           order_time, 
           STRING_TO_ARRAY(exclusions, ', ') AS exclusions_array, 
           STRING_TO_ARRAY(extras, ', ')     AS extras_array
    FROM pizza_runner.customer_orders
),
exclusion_names AS (
    SELECT o.row_id,                                          -- use row_id
           STRING_AGG(t.topping_name, ', ') AS exclusion_topping
    FROM orderitems o
    JOIN pizza_runner.pizza_toppings t ON t.topping_id::text = ANY(o.exclusions_array)
    GROUP BY o.row_id                                      -- group by row_id
),
extra_names AS (
    SELECT o.row_id,                                          -- use row_id
           STRING_AGG(t.topping_name, ', ') AS extra_topping
    FROM orderitems o
    JOIN pizza_runner.pizza_toppings t ON t.topping_id::text = ANY(o.extras_array)
    GROUP BY o.row_id                                      -- group by row_id
)
SELECT o.order_id, o.customer_id, o.pizza_id, o.order_time,
    CASE
        WHEN exclusions_array IS NULL AND extras_array IS NULL THEN pizza_name
        WHEN exclusions_array IS NOT NULL AND extras_array IS NULL THEN CONCAT(pizza_name, ' - Exclude ', exclusion_topping)
        WHEN exclusions_array IS NULL AND extras_array IS NOT NULL THEN CONCAT(pizza_name, ' - Extra ', extra_topping)
        ELSE CONCAT(pizza_name, ' - Exclude ', exclusion_topping, ' - Extra ', extra_topping)
    END AS order_item
FROM orderitems o
JOIN pizza_runner.pizza_names ON o.pizza_id = pizza_names.pizza_id
LEFT JOIN exclusion_names ON o.row_id = exclusion_names.row_id               -- join on row_id
LEFT JOIN extra_names ON o.row_id = extra_names.row_id                   -- join on row_id
ORDER BY o.order_id;

--QUESTION 5
WITH orderitems AS (
    -- Step 1: Add unique row_id to each order row
    SELECT ROW_NUMBER() OVER (ORDER BY order_id) AS row_id,
           order_id, 
           customer_id, 
           pizza_id, 
           order_time, 
           STRING_TO_ARRAY(exclusions, ', ') AS exclusions_array, 
           STRING_TO_ARRAY(extras, ', ')     AS extras_array
    FROM pizza_runner.customer_orders
),
standard_toppings AS (
    -- Step 2: Get all standard toppings for each pizza
    SELECT o.row_id,
           o.order_id,
           o.pizza_id,
           t.topping_id,
           t.topping_name
    FROM orderitems o
    JOIN pizza_runner.pizza_recipes r ON o.pizza_id = r.pizza_id
    JOIN pizza_runner.pizza_toppings t ON t.topping_id::text = ANY(STRING_TO_ARRAY(r.toppings, ', '))
),
after_exclusions AS (
    -- Step 3: Remove excluded toppings from standard toppings
    SELECT s.row_id,
           s.order_id,
           s.pizza_id,
           s.topping_id,
           s.topping_name
    FROM standard_toppings s
    JOIN orderitems o ON s.row_id = o.row_id
    WHERE o.exclusions_array IS NULL                       -- no exclusions at all
       OR s.topping_id::text != ALL(o.exclusions_array)    -- topping not in exclusions
),
with_extras AS (
    -- Step 4: Add extras, mark as 2x if already in standard toppings
    SELECT o.row_id,
           o.order_id,
           o.pizza_id,
           t.topping_id,
        CASE 
            WHEN t.topping_id::text = ANY(STRING_TO_ARRAY(r.toppings, ', ')) 
            THEN '2x' || t.topping_name    -- already a standard topping → 2x
            ELSE t.topping_name            -- new topping → normal
        END AS topping_name
    FROM orderitems o
    JOIN pizza_runner.pizza_toppings t ON t.topping_id::text = ANY(o.extras_array)
    JOIN pizza_runner.pizza_recipes r ON o.pizza_id = r.pizza_id
    WHERE o.extras_array IS NOT NULL
),
all_toppings AS (
    -- Step 5: Combine standard (after exclusions) + extras
    SELECT row_id, order_id, pizza_id, topping_id, topping_name 
    FROM after_exclusions
    UNION ALL
    SELECT row_id, order_id, pizza_id, topping_id, topping_name 
    FROM with_extras
)
-- Step 6: Aggregate alphabetically and format
SELECT a.order_id,
       a.row_id,
       CONCAT(
        	n.pizza_name, ': ',
        	STRING_AGG(a.topping_name, ', ' ORDER BY a.topping_name)
    ) AS ingredient_list
FROM all_toppings a
JOIN pizza_runner.pizza_names n ON a.pizza_id = n.pizza_id
GROUP BY a.row_id, a.order_id, a.pizza_id, n.pizza_name
ORDER BY a.order_id, a.row_id;

--QUESTION 6
WITH delivered_orders AS (
    -- Step 1: Get only delivered orders
    SELECT 
        ROW_NUMBER() OVER (ORDER BY c.order_id) AS row_id,
        c.order_id, 
        c.customer_id, 
        c.pizza_id, 
        c.order_time, 
        STRING_TO_ARRAY(c.exclusions, ', ') AS exclusions_array, 
        STRING_TO_ARRAY(c.extras, ', ')     AS extras_array
    FROM pizza_runner.customer_orders c
    JOIN pizza_runner.runner_orders r 
        ON c.order_id = r.order_id
    WHERE r.distance IS NOT NULL              -- only delivered orders
),
standard_toppings AS (
    -- Step 2: Get standard toppings for each delivered pizza
    SELECT 
        o.row_id,
        t.topping_id,
        t.topping_name
    FROM delivered_orders o
    JOIN pizza_runner.pizza_recipes r 
        ON o.pizza_id = r.pizza_id
    JOIN pizza_runner.pizza_toppings t 
        ON t.topping_id::text = ANY(STRING_TO_ARRAY(r.toppings, ', '))
),
after_exclusions AS (
    -- Step 3: Remove excluded toppings
    SELECT 
        s.row_id,
        s.topping_id,
        s.topping_name
    FROM standard_toppings s
    JOIN delivered_orders o 
        ON s.row_id = o.row_id
    WHERE o.exclusions_array IS NULL
       OR s.topping_id::text != ALL(o.exclusions_array)
),
extras AS (
    -- Step 4: Get extras (each extra counts as additional usage)
    SELECT
        o.row_id,
        t.topping_id,
        t.topping_name
    FROM delivered_orders o
    JOIN pizza_runner.pizza_toppings t 
        ON t.topping_id::text = ANY(o.extras_array)
    WHERE o.extras_array IS NOT NULL
),
all_toppings AS (
    -- Step 5: Combine standard toppings + extras
    SELECT topping_id, topping_name FROM after_exclusions
    UNION ALL
    SELECT topping_id, topping_name FROM extras
)
-- Step 6: Count each ingredient and sort
SELECT 
    topping_name,
    COUNT(*) AS times_used
FROM all_toppings
GROUP BY topping_id, topping_name
ORDER BY times_used DESC;


------------------------------------------------------------------------------------------------------------------
------------------------------------------Pricing and Ratings--------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--QUESTION 1
SELECT SUM(
			CASE 
				WHEN pizza_id = 1 THEN 12
				WHEN pizza_id = 2 THEN 10
		    END
		  ) AS Total_Earned
FROM pizza_runner.customer_orders;

--QUESTION 2
WITH delivered_orders AS (
    -- Only delivered orders
    SELECT 
        c.order_id,
        c.pizza_id,
        STRING_TO_ARRAY(c.extras, ', ') AS extras_array
    FROM pizza_runner.customer_orders c
    JOIN pizza_runner.runner_orders r 
        ON c.order_id = r.order_id
    WHERE r.distance IS NOT NULL
),
base_price AS (
    -- Step 1: Calculate base price per pizza
    SELECT
        order_id,
        extras_array,
        CASE 
            WHEN pizza_id = 1 THEN 12
            WHEN pizza_id = 2 THEN 10
        END AS pizza_price
    FROM delivered_orders
),
extras_charge AS (
    -- Step 2: Calculate extras charge per pizza row
    SELECT 
        b.order_id,
        b.pizza_price,
        SUM(
            CASE 
                WHEN t.topping_id = 4 THEN 2   -- Cheese = $1 extra on top of $1
                ELSE 1                          -- all other extras = $1
            END
        ) AS extra_cost
    FROM base_price b
    JOIN pizza_runner.pizza_toppings t
        ON t.topping_id::text = ANY(b.extras_array)
    WHERE b.extras_array IS NOT NULL
    GROUP BY b.order_id, b.pizza_price
)
-- Step 3: Sum base price + extras
SELECT
    SUM(b.pizza_price) + COALESCE(SUM(extra_cost), 0) AS total_earned
FROM base_price b
LEFT JOIN extras_charge e 
    ON b.order_id = e.order_id;

--QUESTION 3
CREATE TABLE pizza_runner.ratings (
    rating_id       SERIAL          PRIMARY KEY,
    order_id        INT             NOT NULL,
    customer_id     INT             NOT NULL,
    runner_id       INT             NOT NULL,
    rating          INT             NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review          VARCHAR(255),
    rated_at        TIMESTAMP       DEFAULT NOW()
);

INSERT INTO pizza_runner.ratings 
    (order_id, customer_id, runner_id, rating, review)
VALUES
    (1,  101, 1, 5, 'Super fast delivery!'),
    (2,  101, 1, 4, 'Great service'),
    (3,  102, 1, 3, 'A little late but friendly'),
    (4,  103, 2, 5, 'Perfect delivery'),
    (5,  104, 3, 2, 'Took longer than expected'),
    (7,  105, 2, 5, 'Excellent runner!'),
    (8,  102, 2, 4, 'Good service'),
    (10, 104, 1, 5, 'Amazing, will order again!');

--QUESTION 4
SELECT 
    c.customer_id,
    c.order_id,
    r.runner_id,
    rt.rating,
    c.order_time,
    r.pickup_time,
    -- Time between order and pickup
    FLOOR(EXTRACT(EPOCH FROM (r.pickup_time::timestamp - c.order_time::timestamp)) / 60) AS prep_time_minutes,
    -- Delivery duration
    r.duration                                                    AS delivery_duration_minutes,
    -- Average speed
    ROUND((r.distance / r.duration * 60)::numeric, 2)            AS avg_speed_kmh,
    -- Total number of pizzas per order
    COUNT(c.pizza_id)                                             AS total_pizzas
FROM pizza_runner.customer_orders c
JOIN pizza_runner.runner_orders r
    ON c.order_id = r.order_id
JOIN pizza_runner.ratings rt
    ON c.order_id = rt.order_id
WHERE r.distance IS NOT NULL                                      -- successful deliveries only
GROUP BY 
    c.customer_id,
    c.order_id,
    r.runner_id,
    rt.rating,
    c.order_time,
    r.pickup_time,
    r.duration,
    r.distance
ORDER BY c.order_id;

--QUESTION 5
WITH revenue AS (
    -- Step 1: Calculate revenue from delivered pizzas
    SELECT 
        SUM(
            CASE 
                WHEN c.pizza_id = 1 THEN 12    -- Meat Lovers
                WHEN c.pizza_id = 2 THEN 10    -- Vegetarian
            END
        ) AS total_revenue
    FROM pizza_runner.customer_orders c
    JOIN pizza_runner.runner_orders r
        ON c.order_id = r.order_id
    WHERE r.distance IS NOT NULL               -- delivered orders only
),
runner_cost AS (
    -- Step 2: Calculate runner payments (unique orders only)
    SELECT 
        SUM(distance * 0.30) AS total_runner_cost
    FROM pizza_runner.runner_orders
    WHERE distance IS NOT NULL                 -- delivered orders only
)
-- Step 3: Calculate leftover
SELECT 
    total_revenue,
    ROUND(total_runner_cost::numeric, 2)                        AS total_runner_cost,
    ROUND((total_revenue - total_runner_cost)::numeric, 2)      AS leftover
FROM revenue, runner_cost;