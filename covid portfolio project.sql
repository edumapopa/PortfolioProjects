
SELECT * FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2
UPDATE [Portfolio Project]..CovidDeaths
SET total_cases = ISNULL(total_cases,0), total_deaths = ISNULL(total_deaths,0)
WHERE total_cases IS NULL OR total_deaths IS NULL


-- Total Cases vs Total Deaths 


SELECT location, date, total_cases, total_deaths, (CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 as DeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
AND location LIKE '%states%'
ORDER BY 1,2

--Total Cases vs Population

SELECT location, date, population, total_cases, (CONVERT(float,total_cases)/CONVERT(float,population))*100 as PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
--AND location LIKE '%states%'
ORDER BY 1,2

-- People Infected vs People Died, based on the entire population

SELECT location, date, population, (CONVERT(float,total_cases)/CONVERT(float,population))*100 as PeopleInfected, (CONVERT(float,total_deaths)/CONVERT(float,population))*100 as PeopleDied
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
-- AND location LIKE '%states%'
ORDER BY 1,2 desc

-- Looking at the Highest Infection Rate (compared to Population) per country now!

SELECT location, population, MAX(CONVERT(float,total_cases)) as HighestInfectionCount, MAX((CONVERT(float,total_cases)/CONVERT(float,population)))*100 as PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing highest death count per country and percent death population compared to Population

SELECT location, population, MAX(CONVERT(float,total_deaths)) as TotalDeathCount, MAX((CONVERT(float,total_deaths)/NULLIF(CONVERT(float,population),0)))*100 as PercentDeathPopulation
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount desc

--Simplier: show highest death count

SELECT location, MAX(CONVERT(float,total_deaths)) as TotalDeaths
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeaths desc

-- LET'S BREAK THINGS DOWN BY CONTINENT

SELECT location, MAX(CONVERT(float,total_deaths)) as TotalDeaths
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeaths desc

-- Showing continents with highest death count per population
SELECT continent, MAX(CONVERT(float,total_deaths)) as TotalDeaths
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeaths desc


--GLOBAL NUMBERS

--total number of cases/deaths each day across the world
SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/NULLIF(SUM(new_cases),0) as DeathPercentage_PeopleInfected
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

--remember: percetage over people infected
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/NULLIF(SUM(new_cases),0) as DeathPercentage_PeopleInfected
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
--ORDER BY date

-- Looking at Total Populations vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated 
--, (RollingPeopleVaccinated)/population 
FROM [Portfolio Project]..CovidDeaths dea 
JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
order by 2,3

-- USE CTE 

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea
	JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--order by 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac
order by 2,3


--OR TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea
	JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--order by 2,3

SELECT * , (RollingPeopleVaccinated/population)*100 as PercentagePeopleVacinnated
FROM #PercentPopulationVaccinated
ORDER BY 2,3



-- CREATE VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW PeopleVacinnated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--order by 2,3

SELECT *
FROM PeopleVacinnated