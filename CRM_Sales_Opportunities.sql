CREATE SCHEMA crm_sales_oppties;
USE crm_sales_oppties;


-- 1 PIPELINE METRICS
-- Calculate the number of sales opportunities created each month using "engage_date", and identify the month with the most opportunities
SELECT YEAR(engage_date) as yr,
	   MONTH(engage_date) as mnt,
       COUNT(DISTINCT opportunity_id) AS number_of_oppty
FROM sales_pipeline
GROUP BY 1,2
ORDER BY 3 DESC; -- the most opportunities were in year 2017: July - 796 and in year 2016: December - 196

-- Find the average time deals stayed open (from "engage_date" to "close_date"), and compare closed deals versus won deals
SELECT ROUND(AVG(DATEDIFF(close_date, engage_date))) AS avg_days_deal_open,
	   COUNT(opportunity_id) AS closed_deals,
       COUNT(CASE WHEN deal_stage = "Won" THEN opportunity_id END) AS won_deals,
       COUNT(CASE WHEN deal_stage = "Won" THEN opportunity_id END)/COUNT(opportunity_id) won_to_closed_d
FROM sales_pipeline;  -- avg time deals open 48 days, won_to_closed deals ratio is 0.63

-- Calculate the percentage of deals in each stage, and determine what share were lost
SELECT DISTINCT deal_stage FROM sales_pipeline; -- only 2 stages: Won and Lost
SELECT
	ROUND(COUNT(CASE WHEN deal_stage = "Won" THEN opportunity_id END)/COUNT(DISTINCT opportunity_id),2) AS share_won_deals,
    ROUND(COUNT(CASE WHEN deal_stage = "Lost" THEN opportunity_id END)/COUNT(DISTINCT opportunity_id),2) AS share_lost_deals,
    COUNT(DISTINCT opportunity_id) AS total_deals
FROM sales_pipeline; -- 63% won, 37% lost

-- Compute the win rate for each product, and identify which one had the highest win rate
SELECT COUNT(DISTINCT product) FROM sales_pipeline; -- 7 products
SELECT 
	product,
    ROUND(COUNT(CASE WHEN deal_stage = "Won" THEN opportunity_id END)/COUNT(opportunity_id)*100) AS win_rate_prct
FROM sales_pipeline
GROUP BY 1
ORDER BY 2 DESC; -- MG Special has the highest win rate


-- 2 SALES AGENTS PERFORMANCE
-- Calculate the win rate for each sales agent, and find the top performer
SELECT 
	sales_agent,
    ROUND(COUNT(CASE WHEN deal_stage = "Won" THEN opportunity_id END)/COUNT(opportunity_id), 2) AS win_rate
FROM sales_pipeline
GROUP BY 1
ORDER BY 2 DESC; -- Top performers: Maureen Marcano, Hayden Neloms, Wilburn Farren with win_rate 70%

-- Calculate the total revenue by agent, and see who generated the most
SELECT 
	sales_agent,
    SUM(close_value) AS revenue
FROM sales_pipeline
GROUP BY 1
ORDER BY 2 DESC;  -- Darcel Schlecht generated the most value 1,153,214

-- Calculate win rates by manager to determine which manager’s team performed best
SELECT 
	st.manager,
    ROUND(COUNT(CASE WHEN sp.deal_stage = "Won" THEN sp.opportunity_id END)/COUNT(sp.opportunity_id), 2) AS win_rate
FROM sales_pipeline sp
	LEFT JOIN sales_teams st
		ON sp.sales_agent=st.sales_agent
GROUP BY 1
ORDER BY 2 DESC; -- Summer Sewalds' and Cara Losch's teams has the highest win_rates 64%.

-- For the product GTX Plus Pro, find which regional office sold the most units
SELECT
	regional_office,
	COUNT(opportunity_id) AS units_sold
FROM sales_pipeline sp
	LEFT JOIN sales_teams st
		ON sp.sales_agent=st.sales_agent
WHERE product='GTX Plus Pro'
GROUP BY 1
ORDER BY 2 DESC; -- Central regional office sold the most GTX Plus Pro units = 264


-- 3 PRODUCT ANALYSIS
-- For March deals, identify the top product by revenue and compare it to the top by units sold
SELECT  
	product,
    SUM(close_value) AS revenue_march,
	COUNT(opportunity_id)AS sold_by_units_march
FROM sales_pipeline
WHERE YEAR(close_date) = '2017' 
AND MONTH(close_date) = '3'
AND LOWER(deal_stage) ='won'
GROUP BY 1
ORDER BY 2 DESC; -- Top by revenue: GTXPro=376966 MG Advanced=290207
-- ORDER BY 3 DESC; -- Top by units sold: GTX Basic=126, MG Special=107

-- Calculate the average difference between "sales_price" and "close_value" for each product, and note if the results suggest a data issue

-- GTX Pro is spelled incorrectly in sales_pipeline table (GTXPro instead of GTX Pro)
SELECT *
FROM sales_pipeline
WHERE product = 'GTXPro';

-- Updating product name
SET SQL_SAFE_UPDATES = 0;
UPDATE sales_pipeline
SET product = 'GTX Pro'
WHERE product = 'GTXPro';
SET SQL_SAFE_UPDATES = 1; 

SELECT sp.product,
	   ROUND(AVG(p.sales_price - sp.close_value),2) AS avg_sales_diff,
       AVG(sp.close_value / p.sales_price) AS discount
FROM sales_pipeline sp
	LEFT JOIN products p
		ON sp.product=p.product
WHERE LOWER(sp.deal_stage)='won'
GROUP BY 1
ORDER BY 2 DESC; 
-- difference for GTK 500 is quite larg, however in percentage to price the discount is less than 0.2%

-- Calculate total revenue by product series and compare their performance
SELECT  series,
		SUM(close_value) AS total_revenue
FROM sales_pipeline sp
	LEFT JOIN products p
		ON sp.product=p.product
GROUP BY 1
ORDER BY 2 DESC; -- GTX series generates much more revenue (7mill) in comparison to other products, MG is top 2 - 2mil and GTK generates the least revenue 400k


-- 4 ACCOUNT ANALYSIS
-- Calculate revenue by office location, and identify the lowest performer
SELECT office_location, SUM(revenue) AS location_revenue
FROM accounts
GROUP BY 1
ORDER BY 2; -- low performers: China

-- Find the gap in years between the oldest and newest customer, and name those companies
SELECT MAX(year_established)- MIN(year_established) AS gap_in_years
FROM accounts;

SELECT MIN(year_established) AS min_year, MAX(year_established) AS max_year
FROM accounts; -- min year 1979, max year 2017

SELECT account, sector, year_established
FROM accounts
WHERE year_established = 1979 OR year_established = 2017;

-- Which accounts that were subsidiaries had the most lost sales opportunities?
SELECT 
	a.account,
	COUNT(opportunity_id) AS lost_opp
FROM accounts a
LEFT JOIN sales_pipeline sp
	ON a.account=sp.account
WHERE deal_stage='Lost'
 -- AND subsidiary_of IS NOT NULL -- doesn't fit because values are not null, just empty in subsidiary_of column
 AND LENGTH(subsidiary_of)>1
GROUP BY 1
ORDER BY 2 DESC;

SELECT *
FROM sales_pipeline;
SELECT *
FROM accounts;

-- Join the companies to their subsidiaries. Which one had the highest total revenue?
WITH parent_account AS (SELECT account,
						CASE WHEN subsidiary_of = '' THEN account ELSE subsidiary_of END AS parent_account
						FROM accounts)
SELECT 
	parent_account,
    SUM(close_value) AS total_revenue
FROM parent_account pa
JOIN sales_pipeline sp
ON pa.account=sp.account
GROUP BY 1
ORDER BY 2 DESC;
