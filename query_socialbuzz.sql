---Data cleaning---
--a. Remove duplicates
--b. standardized data
--c. null values/blank
--d. remove unnescesary column or choose nescesary column--

--step 1. duplicate table for data cleaning: to avoid--
--unpredictable mistakes--

--step 2. remove duplicate using CTE and partition
---checking duplicate data, result 0 duplicate data--

WITH cte_duplicate AS (
	SELECT 
		content_id, 
		user_id, 
		content_type, 
		category, 
		ROW_NUMBER () OVER 
		(PARTITION BY  
			content_id, 
			user_id, 
			content_type, 
			category) AS duplicate
	FROM content_new )
SELECT 
	content_id, 
	user_id, 
	content_type, 
	category
FROM cte_duplicate
WHERE duplicate >1

-- Checking total unique each coloumn ---	
SELECT 
	COUNT(DISTINCT content_id) AS cnt_content,
	COUNT(DISTINCT user_id) AS cnt_user,
	COUNT(DISTINCT content_type) AS cnt_type,
	COUNT(DISTINCT category) AS cnt_cat
FROM content_new
	
-- Checking each table --
-- From Table: content_new --	
--check, standardize and update category because there's duplicate for 
-- inconsistency Upper and Lower format --

SELECT 
	DISTINCT category AS trim_cat 
	FROM content_new
	ORDER BY category
	
UPDATE content_new
SET category = 'culture'
WHERE category ='Culture';	

UPDATE content_new
SET category = 'animals'
WHERE category ='Animals';

UPDATE content_new
SET category = 'technology'
WHERE category ='Technology';

UPDATE content_new
SET category = 'education'
WHERE category ='Education';

UPDATE content_new
SET category = 'fitness'
WHERE category ='Fitness';

UPDATE content_new
SET category = 'food'
WHERE category ='Food';

UPDATE content_new
SET category = 'healthy eating'
WHERE category ='Healthy Eating';

UPDATE content_new
SET category = 'public speaking'
WHERE category ='Public Speaking';

UPDATE content_new
SET category = 'science'
WHERE category ='Science';


UPDATE content_new
SET category = 'soccer'
WHERE category ='Soccer';

UPDATE content_new
SET category = 'studying'
WHERE category ='Studying';

UPDATE content_new
SET category = 'travel'
WHERE category ='Travel';

UPDATE content_new
SET category = 'veganism'
WHERE category ='Veganism';

--Checking Null value, result: no Null value
--except for url column
SELECT * 
FROM content_new 
WHERE  content_type IS NULL

SELECT content_id, user_id, content_type, category FROM content_new

-- From Table: reaction_new --	
	
--check, standardize and update category in case any duplicate--
--duplicate = 0

WITH cte_duplicate AS (
	SELECT *, ROW_NUMBER () OVER 
	(PARTITION BY content_id, user_id, reac_type, datetime) AS duplicate
FROM reaction_new
	)
SELECT * FROM cte_duplicate WHERE duplicate >1

-- checking and make sure no duplicate in reaction_new table --	
SELECT DISTINCT reac_type FROM reaction_new ORDER BY reac_type
	
SELECT * FROM reaction_new

--Check NULL value from reaction_new tabel
--deleting row with Null value from reac_type column 
	
SELECT content_id, reac_type, datetime
	FROM reaction_new
	WHERE reac_type IS NULL

SELECT COUNT(content_id)
	FROM reaction_new
	WHERE reac_type IS NULL

DELETE
	FROM reaction_new
	WHERE reac_type IS NULL

	
---Data Analyzing--
-- query 1) combine 3 tables using Join clause ---
	
SELECT
	con.user_id,
	r.datetime,
	con.content_type,
	con.category,
	rt.sentiment,
	r.reac_type,
	rt.score
FROM content_new AS con
INNER JOIN reaction_new AS r
	ON con.content_id = r.content_id
INNER JOIN reaction_type_new AS rt
	ON r.reac_type = rt.reac_type

------ Query 2) TOP 5 Categories---
SELECT
	con.category,
	SUM(rt.score) AS top_5
FROM content_new AS con
INNER JOIN reaction_new AS r
	ON con.content_id = r.content_id
INNER JOIN reaction_type_new AS rt
	ON r.reac_type = rt.reac_type
GROUP BY con.category
ORDER BY top_5 DESC
LIMIT 5
	
-- Query 3) Busiest month --
WITH cte_month AS (
SELECT
	r.datetime,
	EXTRACT (MONTH FROM r.datetime) AS month_extract,
	EXTRACT (YEAR FROM r.datetime) AS year_extract,
	con.content_type,
	con.category,
	con.user_id
FROM content_new AS con
INNER JOIN reaction_new AS r
	ON con.content_id = r.content_id
INNER JOIN reaction_type_new AS rt
	ON r.reac_type = rt.reac_type
ORDER BY r.datetime
	)
SELECT 
	month_extract,
	year_extract,
	COUNT(user_id) AS count_traffic
FROM cte_month
GROUP BY month_extract, year_extract
ORDER BY year_extract, month_extract
	
-- Query 4) User Interactions by Category and content type---
SELECT 
	con.category,
	COUNT (CASE
	WHEN con.content_type = 'photo' THEN 1 END) AS photo,
	COUNT (CASE
	WHEN con.content_type = 'video' THEN 1 END) AS video,
	COUNT (CASE
	WHEN con.content_type = 'audio' THEN 1 END) AS audio,
	COUNT (CASE
	WHEN con.content_type = 'GIF' THEN 1 END) AS GIF
FROM content_new AS con
INNER JOIN reaction_new AS r
	ON con.content_id = r.content_id
INNER JOIN reaction_type_new AS rt
	ON r.reac_type = rt.reac_type
GROUP BY con.category

---Query 5) Sentiment---

SELECT
	rt.sentiment,
	SUM(rt.score)
FROM content_new AS con
INNER JOIN reaction_new AS r
	ON con.content_id = r.content_id
INNER JOIN reaction_type_new AS rt
	ON r.reac_type = rt.reac_type
GROUP BY rt.sentiment

-- Query 6) total score--

SELECT
	SUM(rt.score) AS total_score
FROM content_new AS con
INNER JOIN reaction_new AS r
	ON con.content_id = r.content_id
INNER JOIN reaction_type_new AS rt
	ON r.reac_type = rt.reac_type

-- Query 7) total user interactions--
SELECT
	COUNT(con.user_id) AS user_interactions
FROM content_new AS con
INNER JOIN reaction_new AS r
	ON con.content_id = r.content_id
INNER JOIN reaction_type_new AS rt
	ON r.reac_type = rt.reac_type	

-- Query 8) there's 438 total unique user--
SELECT 
	COUNT (DISTINCT con.user_id) AS click_count
FROM content_new AS con
INNER JOIN reaction_new AS r
	ON con.content_id = r.content_id
INNER JOIN reaction_type_new AS rt
	ON r.reac_type = rt.reac_type

--Query 9) intensity user behaviour--

WITH count_cte AS (
	SELECT 
		con.user_id,
		COUNT (con.user_id) AS click_count
FROM content_new AS con
INNER JOIN reaction_new AS r
	ON con.content_id = r.content_id
INNER JOIN reaction_type_new AS rt
	ON r.reac_type = rt.reac_type
GROUP BY con.user_id
ORDER BY click_count DESC
)
SELECT 
	click_count,
	COUNT(click_count)  AS total_person
FROM count_cte
group by click_count
ORDER BY total_person DESC

--Query 10) Top content type based on category---	
WITH cte_rank AS (SELECT
	con.category,
	con.content_type,
	COUNT( con.content_type) AS cnt_type,
	RANK () OVER (PARTITION BY category ORDER BY 
		COUNT( con.content_type) DESC) AS ranking
FROM content_new AS con
INNER JOIN reaction_new AS r
	ON con.content_id = r.content_id
INNER JOIN reaction_type_new AS rt
	ON r.reac_type = rt.reac_type
GROUP BY con.content_type, con.category	
ORDER BY con.category, COUNT( con.content_type) DESC
)
SELECT 
	category,
	content_type,
	cnt_type,
	ranking
FROM cte_rank
WHERE ranking = 1
ORDER BY cnt_type DESC




