

-- SQL Data Exploration Project -- COVID-19 data --
-- Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types --

SET ARITHABORT OFF
SET ANSI_WARNINGS OFF


-- All CovidDeaths data query --


SELECT *
FROM ProjectPortfolio1..CovidDeaths
WHERE continent is not null
ORDER BY 3,4


-- More specific query using ORDER BY--


SELECT continent, location, date, total_cases, total_deaths
FROM ProjectPortfolio1..CovidDeaths
where continent is not null
ORDER BY 1, 2, 3


-- United Kingdom DeathPercentage -- shows the likelihood of dying if contracting COVID in the UK --
-- DeathPercentage trimmed to 2 decimal places --


SELECT continent, location, date, total_cases, total_deaths, cast((total_deaths/total_cases)*100 AS decimal(18,2)) AS DeathPrecentage
FROM ProjectPortfolio1..CovidDeaths
WHERE location like '%United King%'
AND continent is not null
ORDER BY 1, 2, 3


-- UK Infection rate -- shows the likelihood of getting infected in the UK --


SELECT continent, location, date, population, total_cases, (total_cases/population)*100 AS InfectionRate
FROM ProjectPortfolio1..CovidDeaths
WHERE location like '%United King%'
AND continent is not null
ORDER BY 1, 2, 3


-- InfectionRate trimmed to 6 decimal places --


SELECT continent, location, date, population, total_cases, cast((total_cases/population)*100 AS decimal(18,6)) AS InfectionRate
FROM ProjectPortfolio1..CovidDeaths
WHERE location like '%United King%'
AND continent is not null
ORDER BY 1, 2, 3

-- Countries with highest infection rate per population --
SELECT continent, location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases)/population)*100 AS PercentPopulationInfected
FROM ProjectPortfolio1..CovidDeaths
WHERE continent is not null
GROUP BY continent, location, population
ORDER BY 4 DESC


--Countries with highest death rate per population --


SELECT continent, location, population, MAX(total_deaths) AS HighestDeathCount, (MAX(total_deaths)/population)*100 AS PercentPopulationDied
FROM ProjectPortfolio1..CovidDeaths
WHERE continent is not null
GROUP BY continent, location, population
ORDER BY 4 DESC


--Highest death count grouped by continent per population --


SELECT continent, MAX(total_deaths) AS HighestDeathCount
FROM ProjectPortfolio1..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY HighestDeathCount DESC


--Global Numbers -- 
-- (total cases/deaths/death %) by day --



SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM ProjectPortfolio1..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2


--UK numbers (total cases/deaths/death %) by day --


SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM ProjectPortfolio1..CovidDeaths
WHERE continent is not null
	AND location like '%United King%'
GROUP BY date
ORDER BY 1, 2


--COVID Vaccinations and rolling numbers of vaccination by country --


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,
	dea.date) AS RollingPeopleVaccinated
FROM ProjectPortfolio1..CovidDeaths dea
JOIN ProjectPortfolio1..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3


-- Show UK's hospital, ICU admissions before and after vaccine roll out --
-- UK's Hospital and ICU numbers with % of ICU per Total hospital admission --


SELECT 
	date, 
	population, 
	total_cases, 
	hosp_patients, 
	icu_patients, 
	(cast(icu_patients AS float)/cast(hosp_patients AS float))*100 AS PercentageOfICUPatients
FROM ProjectPortfolio1..CovidDeaths
WHERE continent is not null
	AND location like '%United King%'
ORDER BY 1


-- Rolling totals (total_cases, total_deaths, hosp_patients, icu_patients--


SELECT 
	date, 
	population, 
	total_cases,
	SUM(cast(total_cases as int)) OVER (PARTITION BY location ORDER BY location,
	date) AS RollingTotalCases,
	hosp_patients, 
	SUM(cast(hosp_patients as int)) OVER (PARTITION BY location ORDER BY location,
	date) AS RollingHospitalPatients,
	icu_patients, 
	SUM(cast(icu_patients as int)) OVER (PARTITION BY location ORDER BY location,
	date) AS RollingICUPatients
FROM ProjectPortfolio1..CovidDeaths
WHERE continent is not null
	AND location like '%United King%'
ORDER BY 1


-- Showing differences between ICU admissions from Previous days --
-- total deaths, new deaths also added to show how many died -- 


SELECT 
	date,
	total_deaths,
	new_deaths,
	icu_patients,
	LAG(icu_patients) 
		OVER (ORDER BY date) AS ICUPatientsPreviousDay,
	cast(icu_patients AS int)-LAG(icu_patients)
		OVER (ORDER BY date) AS DifferencePreviousDay
FROM ProjectPortfolio1..CovidDeaths
WHERE continent is not null
	AND location like '%United King%'
ORDER BY 1


-- CTE to show RollingPeopleVaccinated per population --


WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,
	dea.date) AS RollingPeopleVaccinated
FROM ProjectPortfolio1..CovidDeaths dea
JOIN ProjectPortfolio1..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


--TEMP TABLE to show RollingPeopleVaccinated per population --


DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,
	dea.date) AS RollingPeopleVaccinated
FROM ProjectPortfolio1..CovidDeaths dea
JOIN ProjectPortfolio1..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Creating a view to store data for later visualisations --
-- PercentPopulationVaccinated --


CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,
	dea.date) AS RollingPeopleVaccinated
FROM ProjectPortfolio1..CovidDeaths dea
JOIN ProjectPortfolio1..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null


