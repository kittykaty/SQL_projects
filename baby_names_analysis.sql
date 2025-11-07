USE baby_names_db;

SELECT * FROM names;
SELECT * FROM regions;

-- 1: Track changes in name popularity
-- Find the overall most popular girl and boy names and show how they have changed in popularity rankings over the years

-- most popular female name overall: Jessica 
SELECT
	Name,
    SUM(births) AS total_born
FROM names
WHERE Gender = 'F'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- most popular male name overall: Michael 
SELECT
	Name,
    SUM(births) AS total_born
FROM names
WHERE Gender = 'M'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- gilr names ranking over time
WITH girl_names AS (SELECT 
                Year,
				Name,
				SUM(Births) AS total_births
				FROM names
                WHERE Gender ='F'
				GROUP BY 1,2),
	  pop_rn AS (SELECT 
				Year,
				Name,
				ROW_NUMBER() OVER(PARTITION BY Year ORDER BY total_births DESC) AS popularity_rn
				FROM girl_names)
SELECT *
FROM pop_rn
WHERE Name = 'Jessica'
-- WHERE Name = 'Michael'
;

-- boys names ranking over time
WITH boy_names AS (SELECT 
                Year,
				Name,
				SUM(Births) AS total_births
				FROM names
                WHERE Gender ='M'
				GROUP BY 1,2),
	  pop_rn AS (SELECT 
				Year,
				Name,
				ROW_NUMBER() OVER(PARTITION BY Year ORDER BY total_births DESC) AS popularity_rn
				FROM boy_names)
SELECT *
FROM pop_rn
WHERE Name = 'Michael'
;

-- Find the names with the biggest jumps in popularity from the first year of the data set to the last year
WITH all_names AS (SELECT Year, Name,
				SUM(Births) AS total_births
				FROM names
				GROUP BY Year, Name),
	  names_1980 AS (SELECT Year, Name,
				ROW_NUMBER() OVER(PARTITION BY Year ORDER BY total_births DESC) AS popularity_rn
				FROM all_names
                WHERE Year = 1980),
	  names_2009 AS (SELECT 
				Year, Name,
				ROW_NUMBER() OVER(PARTITION BY Year ORDER BY total_births DESC) AS popularity_rn
				FROM all_names
                WHERE Year = 2009)
SELECT
		n1.Year, n1.Name, n1.popularity_rn,
        n2.Year, n2.Name, n2.popularity_rn,
        CAST(n2.popularity_rn AS SIGNED) - CAST(n1.popularity_rn AS SIGNED)  AS pop_change
FROM names_1980 n1
	INNER JOIN names_2009 n2
		ON n1.Name=n2.Name
ORDER BY pop_change;


-- 2: Compare popularity across decades
-- For each year, return the 3 most popular girl names and 3 most popular boy names
WITH all_names AS (SELECT Gender, Year, Name,
				   SUM(Births) AS total_birth
				   FROM names
				GROUP BY Gender, Year, Name),
		ranks AS ( SELECT Year, Name, Gender,
					ROW_NUMBER() OVER(PARTITION BY Gender, Year ORDER BY total_birth DESC) AS rn
					FROM all_names)
SELECT Year, Name, rn
FROM ranks
WHERE rn < 4
ORDER BY Year, Gender, rn
;

-- For each decade, return the 3 most popular girl names and 3 most popular boy names
WITH all_names AS (SELECT Gender, FLOOR(Year/10)*10 AS decade, Name,
				   SUM(Births) AS total_birth
				   FROM names
				GROUP BY Gender, decade, Name),
		ranks AS ( SELECT decade, Name, Gender,
					ROW_NUMBER() OVER(PARTITION BY Gender, decade ORDER BY total_birth DESC) AS rn
					FROM all_names)
SELECT 
		decade,
	    Name,
        rn
FROM ranks
WHERE rn < 4
ORDER BY decade, Gender, rn
;



-- 3: Compare popularity across regions
-- Return the number of babies born in each of the six regions (NOTE: The state of MI should be in the Midwest region)
SELECT 
		CASE WHEN n.State = 'MI' THEN 'Midwest' ELSE r.Region END AS Region,
        SUM(n.Births) AS num_of_babies
FROM names n
	LEFT JOIN regions r
		ON n.State=r.State
GROUP BY 1
ORDER BY 2 DESC
;

-- Return the 3 most popular girl names and 3 most popular boy names within each region
WITH clean_regions AS (SELECT 
						State,
					    CASE WHEN Region='New England' THEN 'New_England' ELSE Region END AS Region
                        FROM regions
						),
		all_names AS (SELECT 
                        CASE WHEN n.State = 'MI' THEN 'Midwest' ELSE r.Region END AS Region,
                        Gender,
                        Name,
						SUM(n.Births) AS num_of_babies
                        FROM names n
							LEFT JOIN clean_regions r
								ON n.State=r.State
                        GROUP BY 1,2,3),
		pop_names AS (SELECT
                        Region,
                        Name,
                        ROW_NUMBER() OVER(PARTITION BY Region, Gender ORDER BY num_of_babies DESC) AS rn
                        FROM all_names
                    )
SELECT *
FROM pop_names
WHERE rn <4
;




-- 4: Explore unique names in the dataset
-- Find the 10 most popular androgynous names (names given to both females and males)
SELECT 
	Name, 
    COUNT(DISTINCT Gender) AS num_genders, 
    SUM(Births) AS num_genders
FROM names
GROUP BY Name
HAVING num_genders >1
ORDER BY 3 DESC
LIMIT 10;

-- Find the length of the shortest and longest names, and identify the most popular short names (those with the fewest characters)
--  and long names (those with the most characters)
SELECT
	   MIN(LENGTH(Name)) AS shortest_name, -- 2
       MAX(LENGTH(Name)) AS longest_name -- 15
FROM names;

-- most popular long and short names: Ty, Franciscojavier
WITH short_long_names AS (SELECT *
						  FROM names
						  WHERE LENGTH(Name) in (2,15))
SELECT Name, SUM(Births) AS total_births
FROM short_long_names
GROUP BY Name
ORDER BY 2 DESC
LIMIT 100
;

-- The founder of Maven Analytics is named Chris. Find the state with the highest percent of babies named "Chris"
WITH births_chris AS (SELECT State, Name, SUM(Births) AS births_chris
						FROM names
						GROUP BY State, Name
						HAVING Name = 'Chris'),
		births_all AS (SELECT State, SUM(Births) AS births_all
						FROM names
						GROUP BY State)
SELECT
	bc.State,
    (bc.births_chris/ba.births_all)*100 AS prct_chris
FROM births_chris bc
	JOIN births_all ba
		ON bc.State=ba.State
 ORDER BY 2     
