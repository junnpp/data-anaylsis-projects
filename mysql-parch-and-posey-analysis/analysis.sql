
# analysis

# 1. What is the number of events occured for each day per channel?
SELECT
	DATE_FORMAT(event_date, "%Y-%m-%d") AS d
    , channel
    , COUNT(*) AS num_events
FROM web_events
GROUP BY 1, 2
ORDER BY 3 DESC, 1 ;

# 2. Find the average number of events for each channel
WITH
	temp AS (
		SELECT
			DATE_FORMAT(event_date, "%Y-%m-%d") AS d
			, channel
			, COUNT(*) AS num_events
		FROM web_events
		GROUP BY 1, 2
		ORDER BY 3 DESC, 1
    )
    
SELECT
	channel
    , AVG(num_events) AS avg_num_events
FROM temp
GROUP BY channel
ORDER BY 2 DESC;

# 3.Query all orders that occured at the first month in the company's history.
DROP VIEW IF EXISTS by_month;
CREATE VIEW by_month AS
SELECT
	*	
	, DENSE_RANK() OVER(ORDER BY DATE_FORMAT(order_date, "%Y-%m")) AS r
FROM orders;

SELECT *
FROM by_month
WHERE r = 1;

# 4. get the average paper quantity occured at the first month in the company's history.
SELECT
	ROUND(AVG(standard_qty), 2) AS avg_standard_paper_qty
	, ROUND(AVG(gloss_qty), 2) AS avg_gloss_paper_qty
	, ROUND(AVG(poster_qty), 2) AS avg_poster_paper_qty
	, ROUND(SUM(total_amt_usd), 2) AS total_paper_sales
FROM by_month
WHERE r = 1;

# 5. Query all orders that occured at the first day in the company's history.
WITH 
	by_day AS (
		SELECT
			*	
			, DENSE_RANK() OVER(ORDER BY DATE_FORMAT(order_date, "%Y-%m-%d")) AS r
		FROM orders
	) 
    
SELECT *
FROM by_day
WHERE r = 1;
    
# 6. For each account, get the most frequently used channel.

WITH 
	by_freq AS (
		SELECT
			name
			, channel
			, DENSE_RANK() OVER(PARTITION BY name ORDER BY num_events DESC) AS most_freq
		FROM accounts AS t1
		LEFT JOIN (
			SELECT
				account_id
				, channel
				, COUNT(*) AS num_events
			FROM web_events
			GROUP BY
				account_id
				, channel
		) AS t2
		ON t1.id = t2.account_id
	)
    
SELECT *
FROM by_freq
WHERE most_freq = 1;

/* ------------------------------------------ */

# 7. Get total sales for each region
SELECT
    t3.name
    , ROUND(SUM(total_amt_usd), 2) AS total_sale
FROM accounts AS t1
LEFT JOIN sales_reps AS t2
ON t1.sales_rep_id = t2.id
LEFT JOIN region AS t3
ON t2.region_id = t3.id
LEFT JOIN orders AS t4
ON t1.id = t4.account_id
GROUP BY 1
ORDER BY 2 DESC;

# 8. Get maximum sales for each region
SELECT
    t3.name
    , ROUND(MAX(total_amt_usd), 2) AS total_sale
FROM accounts AS t1
LEFT JOIN sales_reps AS t2
ON t1.sales_rep_id = t2.id
LEFT JOIN region AS t3
ON t2.region_id = t3.id
LEFT JOIN orders AS t4
ON t1.id = t4.account_id
GROUP BY 1
ORDER BY 2 DESC;

# 9. For each region, what is the sales_rep name with the largest total sales amount?
DROP VIEW IF EXISTS by_region;
CREATE VIEW by_region AS 
SELECT
	t2.name AS rep_name
	, t3.name AS region_name
	, MAX(total_amt_usd) AS total_sale
FROM accounts AS t1
LEFT JOIN sales_reps AS t2
ON t1.sales_rep_id = t2.id
LEFT JOIN region AS t3
ON t2.region_id = t3.id
LEFT JOIN orders AS t4
ON t1.id = t4.account_id
GROUP BY 1, 2
ORDER BY 3 DESC;

SELECT *
FROM
(
	SELECT *
		, DENSE_RANK() OVER(PARTITION BY region_name ORDER BY total_sale DESC) AS r
	FROM by_region
) AS t
WHERE r = 1
ORDER BY total_sale DESC;

# 10. For each company with the largest total sales amount per region, how many orders were placed?
WITH
	largest AS (
		SELECT *
		FROM
		(
			SELECT *
				, DENSE_RANK() OVER(PARTITION BY region_name ORDER BY total_sale DESC) AS r
			FROM by_region
		) AS t
		WHERE r = 1
		ORDER BY total_sale DESC
	)
    
SELECT
	name
    , COUNT(order_id) AS total_orders
FROM
(
	SELECT
		t3.name
		, t1.id AS order_id
	FROM orders AS t1
	LEFT JOIN accounts AS t2
	ON t1.account_id = t2.id
	LEFT JOIN sales_reps AS t3
	ON t2.sales_rep_id = t3.id
) AS t
WHERE name IN (SELECT rep_name FROM largest)
GROUP BY name
ORDER BY total_orders DESC;

# 11. For the customer who has spent the most money (total_amt_usd), how many web events did they have for each channel?
SELECT
	t1.channel
    , COUNT(*) AS num_events
FROM web_events AS t1
JOIN (
	SELECT account_id
	FROM orders
	GROUP BY account_id
	ORDER BY SUM(total_amt_usd) DESC
	LIMIT 1
) AS t2
ON t1.account_id = t2.account_id
GROUP BY t1.channel
ORDER BY num_events DESC;

# 12. For the top 10 accounts that has spent the most spent money (total_amt_usd), what is the average amount spent?
WITH
	by_total AS (
		SELECT
			account_id
			, DENSE_RANK() OVER(ORDER BY total_spending DESC) AS r
		FROM 
		(
			SELECT
				account_id
				, SUM(total_amt_usd) AS total_spending
			FROM orders
			GROUP BY account_id
		) AS t
	)
    
SELECT
	account_id
    , ROUND(AVG(total_amt_usd), 2) AS avg_total_sales
FROM orders
WHERE account_id IN (
				SELECT account_id
				FROM by_total
				WHERE r <= 10
			)
GROUP BY account_id
ORDER BY avg_total_sales DESC;

# 13. For the companies that has spent more per order on average than the average of all orders, what is the average total_amt_usd?
WITH 
	higher_avg_acc AS (
		SELECT DISTINCT account_id
		FROM
		(
			SELECT
				account_id
				, AVG(total_amt_usd) OVER(PARTITION BY account_id) AS avg_total
			FROM orders
		) AS t
		WHERE avg_total >= (SELECT AVG(total_amt_usd) AS total_avg FROM orders)
	)

SELECT	
	name
    , avg_spent
FROM 
(
	SELECT
		account_id
		, AVG(total_amt_usd) AS avg_spent
	FROM orders
	WHERE account_id IN (SELECT account_id FROM higher_avg_acc)
	GROUP BY account_id
	ORDER BY avg_spent DESC
) AS t1
LEFT JOIN accounts AS t2
ON t1.account_id = t2.id
