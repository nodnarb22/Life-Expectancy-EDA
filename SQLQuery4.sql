/* view data */
SELECT * 
FROM dbo.life_expectancy;

/* see range of years*/
SELECT DISTINCT(Year)
FROM dbo.life_expectancy
ORDER BY Year ;

/* view change in life expectancy over the years */
SELECT Year, AVG(Life_expectancy) AS average_life
FROM dbo.life_expectancy
GROUP BY Year
ORDER BY Year;

/* view average life expectancy of each country */
SELECT Country, AVG(life_expectancy) AS average_life
FROM dbo.life_expectancy
GROUP BY Country
ORDER BY average_life;

/* view GDP vs life expectancy */
SELECT Country, AVG(GDP) AS average_gdp, AVG(life_expectancy) AS average_life
FROM dbo.life_expectancy
WHERE GDP IS NOT NULL
GROUP BY Country
ORDER BY average_gdp DESC;

/* checking max values incase there are errors */
SELECT Country, Year, MAX(life_expectancy) AS max
FROM dbo.life_expectancy
GROUP BY Country, Year
ORDER BY max DESC;

/* Comparing years of school with life expectancy */
SELECT Country, AVG(Schooling) AS avg_school, AVG(Life_expectancy) AS avg_life
FROM dbo.life_expectancy
GROUP BY Country
ORDER BY avg_school DESC;

/* comparing alcohol consumption with life expectancy */
SELECT Country, AVG(Alcohol) AS avg_alcohol, AVG(Life_expectancy) AS avg_life
FROM dbo.life_expectancy
GROUP BY Country
ORDER BY avg_alcohol DESC;

/* average life expectancy by status */
SELECT Year, Status, AVG(Life_expectancy) AS avg_life
FROM dbo.life_expectancy
GROUP BY Status, Year
ORDER BY avg_life DESC;

/* get the biggest descrepency in life expectancy between developed and developing countries */
SELECT a.Status, MAX(a.life_expectancy - b.life_expectancy) AS max_diff
FROM dbo.life_expectancy AS a, dbo.life_expectancy AS b
WHERE a.Status = b.Status AND a.Country <> b.Country
GROUP BY a.Status;

/* get the names of the countries with the biggest discrepency */
SELECT a.Country, a.Year, a.Status, a.Life_expectancy
FROM dbo.life_expectancy AS a
WHERE a.Life_expectancy = 
	(SELECT MIN(b.Life_expectancy)
	FROM dbo.life_expectancy AS b
	WHERE a.Status = b.Status)
UNION ALL
SELECT a.Country, a.Year, a.Status, a.Life_expectancy
FROM dbo.life_expectancy AS a
WHERE a.Life_expectancy = 
	(SELECT MAX(b.Life_expectancy)
	FROM dbo.life_expectancy AS b
	WHERE a.Status = b.Status)
ORDER BY a.Life_expectancy;

/* confirm data errors */
SELECT Country, Year, Status
FROM dbo.life_expectancy
WHERE Country = 'France' OR Country = 'Finland';

/* correct errors as a new table */
SELECT *
INTO life_expectancyV2
FROM dbo.life_expectancy;

UPDATE dbo.life_expectancyV2
SET Status = 'Developed'
WHERE Country = 'Finland' OR Country = 'France';

SELECT Country, Status
FROM dbo.life_expectancyV2
WHERE Country = 'France' OR Country = 'Finland';
							
/* get the biggest change in life expectancy in a country from the data */
WITH cte AS (SELECT a.Country, a.Year AS high_year, b.Year AS low_year, a.Life_expectancy AS high_life, b.Life_expectancy AS low_life,
ABS(a.Life_expectancy - b.Life_expectancy) as change, RANK() OVER (PARTITION BY a.Country ORDER BY ABS(a.Life_expectancy - b.Life_expectancy) DESC) AS rank
FROM dbo.life_expectancy AS a
JOIN dbo.life_expectancy AS b ON a.Country = b.Country AND b.Life_expectancy < a.Life_expectancy)
SELECT Country, high_year, low_year, high_life, low_life, change
FROM cte
WHERE rank = 1
ORDER BY change DESC;

/* check for life expectancy spikes and dips  given criteria */
DECLARE @min_spike_value FLOAT;
SET @min_spike_value = 1.0;

SELECT a.Country, a.Year, c.Life_expectancy as before, a.Life_expectancy AS spike, b.Life_expectancy AS after
FROM dbo.life_expectancy AS a
JOIN dbo.life_expectancy AS b ON a.Country = b.Country
JOIN dbo.life_expectancy AS c ON a.Country = c.Country
WHERE ((a.Life_expectancy > b.Life_expectancy AND a.Life_expectancy > c.Life_expectancy
	AND (a.Life_expectancy - b.Life_expectancy) >= @min_spike_value
	AND (a.Life_expectancy - c.Life_expectancy) >= @min_spike_value) 
	OR (a.Life_expectancy < b.Life_expectancy AND a.Life_expectancy < b.Life_expectancy
	AND (b.Life_expectancy - a.Life_expectancy) >= @min_spike_value
	AND (c.Life_expectancy - a.Life_expectancy) >= @min_spike_value))
	AND a.Year = c.Year + 1 AND a.Year = b.Year -1
ORDER BY a.Life_expectancy, a.Year;
