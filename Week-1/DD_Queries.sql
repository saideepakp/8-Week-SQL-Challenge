--Question 1
Select customer_id, sum(price) as "Total Amount"
FROM dannys_diner.sales
LEFT JOIN dannys_diner.menu on sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;

--Question 2
SELECT customer_id, COUNT(DISTINCT(order_date)) as "# of days visited"
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;

--Question 3
SELECT customer_id, product_id, product_name
FROM (
		SELECT DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as "r_no", 
	   		   customer_id, 
	   		   order_date, 
	           dannys_diner.menu.product_id, 
	           product_name
		FROM dannys_diner.sales
		LEFT JOIN dannys_diner.menu ON sales.product_id = menu.product_id
		ORDER BY customer_id
)
WHERE r_no = 1
GROUP BY customer_id, product_id, product_name 
ORDER BY customer_id;

--------------------------------Method 2

WITH first_item as (
		SELECT DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as "r_no", 
	   		   customer_id, 
	   		   order_date, 
	           dannys_diner.menu.product_id, 
	           product_name
		FROM dannys_diner.sales
		LEFT JOIN dannys_diner.menu ON sales.product_id = menu.product_id

)

SELECT customer_id, product_id, product_name
FROM first_item
WHERE r_no = 1
GROUP By customer_id, product_id, product_name
ORDER BY customer_id;

--Question 4
----------------------------MOST POPULAR ITEM--------------
		Select sales.product_id, product_name, COUNT(sales.product_id) AS "# of times purchased"
		FROM dannys_diner.menu
		JOIN dannys_diner.sales ON menu.product_id = sales.product_id
		GROUP BY sales.product_id,product_name
		ORDER By COUNT(sales.product_id) DESC
		LIMIT 1
---------------------------nO. OF TIMES ORDERED BY EACH CUSTOMER--------------
WITH most_selling AS(
		Select sales.product_id, product_name
		FROM dannys_diner.menu
		JOIN dannys_diner.sales ON menu.product_id = sales.product_id
		GROUP BY sales.product_id,product_name
		ORDER By COUNT(sales.product_id) DESC
		LIMIT 1
)

SELECT customer_id, COUNT(sales.product_id) AS "# of times Ordered"
FROM dannys_diner.sales
JOIN most_selling ON most_selling.product_id = sales.product_id
GROUP BY customer_id
ORDER BY customer_id;

--Question 5
WITH popular_item_per_customer AS(
	SELECT RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(sales.product_id) DESC) AS r_no,
	customer_id, product_name AS "Popular Item", sales.product_id, COUNT(sales.product_id) 
	FROM dannys_diner.sales
	JOIN dannys_diner.menu ON sales.product_id = menu.product_id
	GROUP BY customer_id, product_name, sales.product_id
	ORDER BY customer_id
)

SELECT customer_id, "Popular Item"
FROM popular_item_per_customer
WHERE r_no = 1
ORDER BY customer_id;

--Question 6
WITH first_order AS(
	SELECT ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date) AS r_no,
		   sales.customer_id, 
		   sales.order_date, 
		   product_name
	FROM dannys_diner.sales
	JOIN dannys_diner.menu ON sales.product_id = menu.product_id
	JOIN dannys_diner.members ON sales.customer_id = members.customer_id
	WHERE sales.order_date >= members.join_date
	GROUP BY sales.customer_id, product_name, sales.order_date
)

SELECT customer_id, order_date, product_name
FROM first_order
WHERE r_no = 1;

--Question 7
WITH first_order AS(
	SELECT RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS r_no,
		   sales.customer_id, 
		   sales.order_date, 
		   product_name
	FROM dannys_diner.sales
	JOIN dannys_diner.menu ON sales.product_id = menu.product_id
	JOIN dannys_diner.members ON sales.customer_id = members.customer_id 
	WHERE sales.order_date < members.join_date
	GROUP BY sales.customer_id, product_name, sales.order_date
)

SELECT customer_id, order_date, product_name
FROM first_order
WHERE r_no = 1;

--Question 8
SELECT sales.customer_id, COUNT(sales.product_id) AS "# of Products Purchased", SUM(price) AS "Amount Spent"
FROM dannys_diner.sales
JOIN dannys_diner.menu ON sales.product_id = menu.product_id
JOIN dannys_diner.members ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

--Question 9
SELECT customer_id, 
	   SUM(
			CASE 
			WHEN sales.product_id = 1 THEN price*20
			WHEN sales.product_id = 2 OR sales.product_id = 3 THEN price*10
			END 
		  ) AS Points
FROM dannys_diner.sales
JOIN dannys_diner.menu ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;


--------------------------------Method 2

WITH points_gained AS(
	SELECT customer_id, sales.product_id,
		CASE 
		WHEN sales.product_id = 1 THEN price*20
		WHEN sales.product_id = 2 OR sales.product_id = 3 THEN price*10
		END AS Points
	FROM dannys_diner.sales
	JOIN dannys_diner.menu ON sales.product_id = menu.product_id
	ORDER BY customer_id
)

SELECT customer_id, SUM(points) AS "Total Points Earned"
FROM points_gained
GROUP BY customer_id;

--Question 10
SELECT sales.customer_id, 
	   SUM(
			CASE 
				WHEN sales.order_date < members.join_date AND sales.product_id = 1 THEN price*20
				WHEN sales.order_date < members.join_date AND sales.product_id != 1 THEN price*10	
				WHEN sales.order_date - members.join_date BETWEEN 0 AND 6 THEN price*20
				WHEN sales.order_date - members.join_date > 6 AND sales.product_id = 1 THEN price*20
				WHEN sales.order_date - members.join_date > 6 AND sales.product_id != 1 THEN price*10
				END 
		  ) AS Points
FROM dannys_diner.sales
JOIN dannys_diner.menu ON sales.product_id = menu.product_id
JOIN dannys_diner.members ON sales.customer_id = members.customer_id
WHERE order_date <= '2021-01-31'
GROUP BY sales.customer_id
ORDER BY sales.customer_id;