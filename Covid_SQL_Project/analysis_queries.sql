SELECT * 
FROM covid_deaths
WHERE continent is not NULL

SELECT LOCATION, DATE, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent is not NULL

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if getting covid in your country
SELECT LOCATION, DATE, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM covid_deaths
WHERE continent is not NULL
AND location like '%States%'


-- Total Cases vs Population
-- Shows percentage of population got Covid
SELECT LOCATION, DATE, Population, total_cases, (total_cases/population)*100 as covid_pos_percentage
FROM covid_deaths
WHERE location like '%States%'
AND continent is not NULL

-- Countries with Highest Infection Rate compared to Population
SELECT LOCATION, Population, MAX(total_cases) as highest_covid_pos_count, MAX((total_cases/population))*100 as covid_pos_percentage
FROM covid_deaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY covid_pos_percentage DESC NULLS LAST 
-- In Postgres, nulls are shown first by default in descending order (last in ascending)


-- Countries with Highest Death Count Per Population
SELECT LOCATION, MAX(total_deaths) as total_death_count
FROM covid_deaths
WHERE continent is not NULL 
GROUP BY location
ORDER BY total_death_count DESC NULLS LAST

-- BREAK THINGS UP BY CONTINENT
-- HIGHEST DEATH COUNT BY CONTINENT
SELECT continent, MAX(total_deaths) as total_death_count
FROM covid_deaths
WHERE continent is not NULL 
GROUP BY continent
ORDER BY total_death_count DESC NULLS LAST


-- GLOBAL NUMBERS
-- Total new cases, total new deaths, and death percentage per day globally
SELECT date, SUM(new_cases) as world_new_cases, SUM(new_deaths) as world_new_deaths, (SUM(new_deaths)/ SUM(new_cases)) * 100 as world_death_percentage
FROM covid_deaths
WHERE continent is not NULL 
GROUP BY date
ORDER BY date


-- USE CTE
WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
-- Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
--, (rolling_people_vaccinated/population)*100
FROM covid_deaths dea
JOIN covid_vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent is NOT NULL
-- ORDER BY 2,3 NULLS LAST
)
SELECT *, (rolling_people_vaccinated/population)*100 as vaccinated_population_percentage
FROM pop_vs_vac


-- Creating View to store data for later visualizations
DROP VIEW IF EXISTS percent_population_vaccinated;

CREATE VIEW percent_population_vaccinated as 
WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
-- Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
--, (rolling_people_vaccinated/population)*100
FROM covid_deaths dea
JOIN covid_vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent is NOT NULL
-- ORDER BY 2,3 NULLS LAST
)
SELECT *, (rolling_people_vaccinated/population)*100 as vaccinated_population_percentage
FROM pop_vs_vac

SELECT * FROM percent_population_vaccinated
