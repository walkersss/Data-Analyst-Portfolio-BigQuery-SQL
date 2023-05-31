SELECT Location, date, total_cases, new_cases, total_deaths, population 
FROM `boreal-augury-377208.Covid.CovidDeaths` order by 1,2 LIMIT 1000;

-- Looking at total case & total deaths

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate 
FROM `boreal-augury-377208.Covid.CovidDeaths` WHERE Location='Malaysia' AND total_deaths IS NOT NULL AND total_cases IS NOT NULL order by 1,2;


--Looking at Total cases vs Population
--Shows % of population got Covid, high to low
SELECT Location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected 
FROM `boreal-augury-377208.Covid.CovidDeaths` WHERE Location='Malaysia' AND total_deaths IS NOT NULL AND total_cases IS NOT NULL order by 5 DESC;

--Countries with highest infection rate vs population
SELECT Location, population, MAX(total_cases) as HighestCase, MAX((total_cases/population))*100 as PercentPopulationInfected 
FROM `boreal-augury-377208.Covid.CovidDeaths` --WHERE Location='Malaysia' AND 
WHERE total_deaths IS NOT NULL AND total_cases IS NOT NULL
GROUP BY Location, population ORDER BY PercentPopulationInfected DESC;

--Countries Highest Death Count per Population

SELECT Location, MAX(total_deaths) as TotalDeathCount
FROM `boreal-augury-377208.Covid.CovidDeaths` --WHERE Location='Malaysia' AND 
WHERE continent IS NOT NULL --Without this where clause, the results is not accurate, with continents included
GROUP BY Location ORDER BY TotalDeathCount DESC;

--Continent Highest Death Count per Population

SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM `boreal-augury-377208.Covid.CovidDeaths` --WHERE Location='Malaysia' AND 
WHERE continent IS NOT NULL --Without this where clause, the results is not accurate, with continents included
GROUP BY continent ORDER BY TotalDeathCount DESC;

--Global Case, death, and Death % by day. Results error: division by 0
SELECT date, SUM(new_cases) as NewCase, SUM(cast(new_deaths as int)) as NewDeath, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM `boreal-augury-377208.Covid.CovidDeaths` 
WHERE continent IS NOT NULL 
GROUP BY date ORDER BY 1,2;

--Covid Vaccination Table Exploration JOIN Covid Death Table
SELECT *
FROM `boreal-augury-377208.Covid.CovidDeaths` dea JOIN `boreal-augury-377208.Covid.CovidVaccinations` vac
ON dea.location = vac.location AND dea.date = vac.date
LIMIT 1000;

--Total Population vs Vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM `boreal-augury-377208.Covid.CovidDeaths` dea JOIN `boreal-augury-377208.Covid.CovidVaccinations` vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 1,2,3;

--Use CTE (Common Table Expression)
WITH PopvsVac --(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM `boreal-augury-377208.Covid.CovidDeaths` dea JOIN `boreal-augury-377208.Covid.CovidVaccinations` vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as VaccinePercentage FROM PopvsVac;

--Temp Table (Currently can't execute because DML is not included in BigQuery free plan)
DROP TABLE IF EXISTS boreal-augury-377208.Covid.PercentPopulationVaccinated;
Create TEMPORARY table PercentPopulationVaccinated
(Continent STRING, Location STRING, Date DATETIME, Population NUMERIC, New_vaccinations NUMERIC, RollingPeopleVaccinated NUMERIC);
Insert into PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM `boreal-augury-377208.Covid.CovidDeaths` dea JOIN `boreal-augury-377208.Covid.CovidVaccinations` vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 2,3;

SELECT *, (RollingPeopleVaccinated/Population)*100 as VaccinePercentage FROM PercentPopulationVaccinated;

--Creating VIEW for later visualizations

Create VIEW boreal-augury-377208.Covid.PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM `boreal-augury-377208.Covid.CovidDeaths` dea JOIN `boreal-augury-377208.Covid.CovidVaccinations` vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 2,3;

Select * From boreal-augury-377208.Covid.PercentPopulationVaccinated