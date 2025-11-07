-- Connect to database
USE hospital_db;

-- OBJECTIVE 1: ENCOUNTERS OVERVIEW

-- a. How many total encounters occurred each year?
SELECT 	YEAR(STOP) AS yr,
		COUNT(Id) AS total_encounters
FROM encounters
GROUP BY yr
ORDER BY yr;

-- b. For each year, what percentage of all encounters belonged to each encounter class
-- (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?
SELECT Year(STOP) AS yr,
		ROUND(COUNT(CASE WHEN ENCOUNTERCLASS = 'ambulatory' THEN 1 END)/COUNT(Id),2) AS ambularoty,
        ROUND(COUNT(CASE WHEN ENCOUNTERCLASS = 'outpatient' THEN 1 END)/COUNT(Id),2) AS outpatient,
        ROUND(COUNT(CASE WHEN ENCOUNTERCLASS = 'wellness' THEN 1 END)/COUNT(Id),2) AS wellness,
        ROUND(COUNT(CASE WHEN ENCOUNTERCLASS = 'urgentcare' THEN 1 END)/COUNT(Id),2) AS urgentcare,
        ROUND(COUNT(CASE WHEN ENCOUNTERCLASS = 'emergency' THEN 1 END)/COUNT(Id),2) AS emergency,
        ROUND(COUNT(CASE WHEN ENCOUNTERCLASS = 'inpatient' THEN 1 END)/COUNT(Id),2) AS inpatient
FROM encounters
GROUP BY 1
ORDER BY 1;

-- c. What percentage of encounters were over 24 hours versus under 24 hours?
SELECT
	COUNT(CASE WHEN TIMESTAMPDIFF(HOUR, START, STOP) >= 24 THEN 1 END) AS over_24h,
    ROUND(COUNT(CASE WHEN TIMESTAMPDIFF(HOUR, START, STOP) >= 24 THEN 1 END)/COUNT(Id)*100, 1) AS over_24h_prct,
    COUNT(CASE WHEN TIMESTAMPDIFF(HOUR, START, STOP) < 24 THEN 1 END) AS under_24h,
    ROUND(COUNT(CASE WHEN TIMESTAMPDIFF(HOUR, START, STOP) < 24 THEN 1 END)/COUNT(Id)*100,1) AS under_24h_prct
FROM encounters;



-- OBJECTIVE 2: COST & COVERAGE INSIGHTS

-- a. How many encounters had zero payer coverage, and what percentage of total encounters does this represent?
SELECT
		COUNT(CASE WHEN PAYER_COVERAGE = 0 THEN 1 END) AS zero_payer_coverage,
		ROUND(COUNT(CASE WHEN PAYER_COVERAGE = 0 THEN 1 END) / COUNT(Id)*100,1) AS zero_payer_coverage_prct
FROM encounters;

-- b. What are the top 10 most frequent procedures performed and the average base cost for each?
SELECT 	CODE, DESCRIPTION, 
		COUNT(*) AS num_of_procedures,
        AVG(BASE_COST) AS avg_base_cost
FROM procedures
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10;

-- c. What are the top 10 procedures with the highest average base cost and the number of times they were performed?
SELECT 	CODE, DESCRIPTION, 
		COUNT(*) AS num_of_procedures,
        AVG(BASE_COST) AS avg_base_cost
FROM procedures
GROUP BY 1,2
ORDER BY 4 DESC
LIMIT 10;

-- d. What is the average total claim cost for encounters, broken down by payer?
SELECT NAME, AVG(TOTAL_CLAIM_COST) AS avg_total_claim_cost
FROM encounters e
LEFT JOIN payers p
	ON e.PAYER=p.Id
GROUP BY PAYER
ORDER BY 2 DESC;
;

-- OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS

-- a. How many unique patients were admitted each quarter over time?
SELECT
	YEAR(START) AS yr,
    QUARTER(START) AS qrt,
	COUNT(DISTINCT PATIENT) AS num_of_patients
FROM encounters
GROUP BY 1, 2
ORDER BY 1, 2; 

-- b. How many patients were readmitted within 30 days of a previous encounter? 
-- readmission within 30 days = current start - previous stop <= 30 days
SELECT
 COUNT(DISTINCT PATIENT) AS patients
FROM (
SELECT PATIENT, START, STOP,
	   LAG(STOP) OVER(PARTITION BY PATIENT ORDER BY START) AS prev_stop_date
	   -- LEAD(START) OVER(PARTITION BY PATIENT ORDER BY START) -- next start date
FROM encounters) AS prev_stop
WHERE TIMESTAMPDIFF(DAY, prev_stop_date, START) <30;

-- c. Which patients had the most readmissions?
SELECT
 PATIENT,
 COUNT(*) AS num_of_readmissions
FROM (
SELECT PATIENT, START, STOP,
	   LAG(STOP) OVER(PARTITION BY PATIENT ORDER BY START) AS prev_stop_date
	   -- LEAD(START) OVER(PARTITION BY PATIENT ORDER BY START) -- next start date
FROM encounters) AS prev_stop
WHERE TIMESTAMPDIFF(DAY, prev_stop_date, START) <30
GROUP BY 1
ORDER BY 2 DESC;