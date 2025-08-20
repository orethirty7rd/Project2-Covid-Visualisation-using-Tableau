select *
FROM Portfolio_Project.covid_deaths
ORDER BY 3,4;

select *
FROM Portfolio_Project.covid_vaccinations
ORDER BY 3,4;

-- Select data that I will be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project.covid_deaths
order by 1,2;

-- 1. Total Cases Vs. Total Deaths (whats the % of people who died from the infected)
-- Rough likelihood of dying if you got infected
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate
FROM Portfolio_Project.covid_deaths
order by 1,2;

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate
FROM Portfolio_Project.covid_deaths
WHERE location like '%nigeria%'
order by 1,2;

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate
FROM Portfolio_Project.covid_deaths
WHERE location like '%states%'
order by 1,2;

-- Total Cases vs Population - Infection rates
SELECT location, date, total_cases, population, total_deaths, (total_cases/population)*100 as infection_rate
FROM Portfolio_Project.covid_deaths
WHERE location like '%states%' 
order by 1,2;

-- What Countries have the highest Infection rate per Population
SELECT location, population, MAX(total_cases) as Highest_Infection_count, MAX((total_cases/population))*100 as highest_infection_rate
FROM Portfolio_Project.covid_deaths
GROUP BY location, population
order by Highest_infection_rate desc;

-- Total Death Vs Population - Death rates
SELECT location, date, total_deaths, population, total_cases, (total_deaths/population)*100 as death_rate
FROM Portfolio_Project.covid_deaths
order by 1,2;


-- What Countries have the highest death rates per Population
SELECT location, MAX(total_deaths) as highest_death_count
FROM Portfolio_Project.covid_deaths
GROUP BY location
order by highest_death_count desc;

-- Continents with the highest Death Counts
SELECT location, MAX(total_deaths) AS highest_death_count
FROM Portfolio_Project.covid_deaths
WHERE location IN (
    'World',
    'Europe',
    'North America',
    'European Union',
    'South America',
    'Asia',
    'Africa',
    'Oceania',
    'International'
)
GROUP BY location
ORDER BY highest_death_count DESC;

SELECT location, MAX(total_deaths) as highest_death_count
FROM Portfolio_Project.covid_deaths
WHERE continent is not null
GROUP BY location
order by highest_death_count desc;


-- Global death rates
SELECT 
    date, 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths, 
    (SUM(new_deaths) / SUM(new_cases)) * 100 AS global_death_rate
FROM Portfolio_Project.covid_deaths
WHERE location NOT IN (
      'World',
      'Europe',
      'North America',
      'European Union',
      'South America',
      'Asia',
      'Africa',
      'Oceania',
      'International'
  )
GROUP BY date
ORDER BY date, total_cases;

-- Total death rate
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths, 
    (SUM(new_deaths) / SUM(new_cases)) * 100 AS global_death_rate
FROM Portfolio_Project.covid_deaths
WHERE location NOT IN (
      'World',
      'Europe',
      'North America',
      'European Union',
      'South America',
      'Asia',
      'Africa',
      'Oceania',
      'International'
  )
ORDER BY 1,2;

-- COVID VACCINATIONS
SELECT *
FROM Portfolio_Project.covid_vaccinations;

-- JOINING COVID DEATHS TO COVID VACCINATIONS
SELECT *
FROM Portfolio_Project.covid_deaths AS dea
JOIN Portfolio_Project.covid_vaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date;
    
SELECT COUNT(*) AS total_rows
FROM Portfolio_Project.covid_vaccinations;

SELECT 
dea.continent, 
dea.location, 
dea.date,
dea.population,
vac.new_vaccinations
FROM Portfolio_Project.covid_deaths AS dea
JOIN Portfolio_Project.covid_vaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.location NOT IN (
      'World',
      'Europe',
      'North America',
      'European Union',
      'South America',
      'Asia',
      'Africa',
      'Oceania',
      'International'
  )
ORDER BY 2,3;


-- To get tota vaccinations based on a rolling/add basis
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as cumulative_vaccinations
-- ((SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date))/(dea.population)) * 100 AS vaccination_rate
FROM Portfolio_Project.covid_deaths AS dea
JOIN Portfolio_Project.covid_vaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.location NOT IN (
      'World',
      'Europe',
      'North America',
      'European Union',
      'South America',
      'Asia',
      'Africa',
      'Oceania',
      'International'
  )
ORDER BY 2,3;

-- USING CTE, TEMP TABLES TO GET VACCINATION RATE

-- 1. CTE - to get vaccination rates
with popvsvac (
continent, location, date, population, new_vaccinations, cumulative_vaccinations
) AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as cumulative_vaccinations
FROM Portfolio_Project.covid_deaths AS dea
JOIN Portfolio_Project.covid_vaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.location NOT IN (
      'World',
      'Europe',
      'North America',
      'European Union',
      'South America',
      'Asia',
      'Africa',
      'Oceania',
      'International'
  )
-- ORDER BY 2,3
)

SELECT *, (cumulative_vaccinations)/(population) * 100 AS vaccination_rate
FROM popvsvac;

-- To get top 10 Vaccination rates Per location (in the world)
with popvsvac (
continent, location, population, new_vaccinations, cumulative_vaccinations
) AS(
SELECT dea.continent, dea.location, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as cumulative_vaccinations
FROM Portfolio_Project.covid_deaths AS dea
JOIN Portfolio_Project.covid_vaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.location NOT IN (
      'World',
      'Europe',
      'North America',
      'European Union',
      'South America',
      'Asia',
      'Africa',
      'Oceania',
      'International'
  )
-- ORDER BY 2,3
)

SELECT location, population, MAX(cumulative_vaccinations) as max_vaccinations,
MAX((cumulative_vaccinations)/(population)) * 100 AS Top10_vaccinationrates
FROM popvsvac
WHERE population IS NOT NULL
	AND  cumulative_vaccinations IS NOT NULL
GROUP BY location, population
ORDER BY Top10_vaccinationrates desc
LIMIT 10;

-- 2. Temp Tables

-- 1. Create table
DROP TABLE IF EXISTS vaccinationrate;
CREATE TABLE vaccinationrate (
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATE,
    population BIGINT,
    new_vaccinations BIGINT,
    cumulative_vaccinations BIGINT
);

-- 2. Test count with WHERE clause
SELECT COUNT(*)
FROM Portfolio_Project.covid_deaths AS dea
JOIN Portfolio_Project.covid_vaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.location NOT IN (
      'World',
      'Europe',
      'North America',
      'European Union',
      'South America',
      'Asia',
      'Africa',
      'Oceania',
      'International'
  );

-- 3. If count > 0, then run INSERT
INSERT INTO vaccinationrate
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as cumulative_vaccinations
FROM Portfolio_Project.covid_deaths AS dea
JOIN Portfolio_Project.covid_vaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.location NOT IN (
      'World',
      'Europe',
      'North America',
      'European Union',
      'South America',
      'Asia',
      'Africa',
      'Oceania',
      'International'
  );

-- 4. Check if data was inserted
SELECT COUNT(*) FROM vaccinationrate;

SELECT *, (cumulative_vaccinations/population) * 100 AS vaccination_rate
FROM vaccinationrate;

cumuluted_vaccine_ratesCREATE VIEW cumuluted_vaccine_rates as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as cumulative_vaccinations
FROM Portfolio_Project.covid_deaths AS dea
JOIN Portfolio_Project.covid_vaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.location NOT IN (
      'World',
      'Europe',
      'North America',
      'European Union',
      'South America',
      'Asia',
      'Africa',
      'Oceania',
      'International'
  );

