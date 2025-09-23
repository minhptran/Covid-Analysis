Select *
From CovidAnalysis..CovidDeaths
Where continent is not null
order by 3,4

Select *
From CovidAnalysis..CovidVaccinations
order by 3,4

-- Select Data that I'm gonna use

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidAnalysis..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths in Canada
-- Likelihood of dying if you contract covid in Canada
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidAnalysis..CovidDeaths
Where location like '%Canada%'
order by 1,2


--Looking at Total Cases vs Population
-- Shows what percentage of population got Covid in Canada
Select Location,population, date, Max(total_cases) as HighestContractedCount, MAX((total_cases/population))*100 as Contracted_Percentage
From CovidAnalysis..CovidDeaths
--Where location like '%Canada%'
Group by Location, population, date
order by Contracted_Percentage desc


-- Looking at Countries with Highest Infection Rate compared to Population
Select Location, date, Population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as Percent_Population_Infected
From CovidAnalysis..CovidDeaths

-- Infection rate
	--order by Percent_Population_Infected desc
-- Infection Count
Where continent is not null 
and location not in ('World', 'European Union', 'International')
Group by Location, date, population
order by Percent_Population_Infected desc


-- Showing Countries with Highest death count and death rate
Select location, Population, MAX(cast(Total_deaths as int)) as Total_Death_count, MAX((cast(Total_deaths as int)/population)) as death_Rate
From CovidAnalysis..CovidDeaths
Where continent is not null
Group by location, population
order by Mortality_Rate desc


-- Continents with higest deaths count and rate
Select location, MAX(cast(Total_deaths as int)) as Total_Death_count, MAX((cast(Total_deaths as int)/population)) as death_Rate
From CovidAnalysis..CovidDeaths
Where continent is null
Group by location
order by total_death_count desc



-- Global statistics
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_cases) as DeathRate
From CovidAnalysis..CovidDeaths
Where continent is not null
--Group by date
order by 1,2


-- Joining deaths and vaccinations dataset, getting vaccinated proportion
With PopvsVac (Continent, Location, Date, Population,New_Vaccinations, RollingPeopleVaccinated)
as 
(
-- Total population vs vaccination
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER 
(Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From CovidAnalysis..CovidDeaths dea
join CovidAnalysis..CovidVaccinations vac
	On dea.location = vac.location  
	and dea.date = vac.date  
where dea.continent is not null
 -- order by date 
)
-- Use CTE
Select *, (RollingPeopleVaccinated/population)*100 as PercentageVaccinated
From PopvsVac



-- Remove duplicate files, get new & total vaccination numbers, percent vaccinated by day
WITH d AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY location, date ORDER BY (SELECT 0)) AS rn
  FROM CovidAnalysis..CovidDeaths
),
v AS (
  SELECT * FROM CovidAnalysis..CovidVaccinations
),
j AS (
  SELECT
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations,
    d.total_deaths,
    SUM(CONVERT(bigint, COALESCE(v.new_vaccinations,0)))
      OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
  FROM d
  JOIN v
    ON v.location = d.location
   AND v.date     = d.date
  WHERE d.rn = 1
    AND d.continent IS NOT NULL
)
SELECT continent, location, date, population, new_vaccinations,RollingPeopleVaccinated,
CAST(100.0 * RollingPeopleVaccinated / NULLIF(CAST(population AS float), 0) AS decimal(6,2))
    AS PercentVaccinated,
    total_deaths,
    (total_deaths/population)*100 as DeathPercentage
    
FROM j
ORDER BY 2,3;



-- Temp table

DROP Table if exists #PercentPopulationVaccinated
create Table #PercentPopulationVaccinated

(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER 
(Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From CovidAnalysis..CovidDeaths dea
join CovidAnalysis..CovidVaccinations vac
	On dea.location = vac.location  
	and dea.date = vac.date  
--where dea.continent is not null
 -- order by date 
Select*, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Create View to store data for later visualizations
Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER 
(Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From CovidAnalysis..CovidDeaths dea
join CovidAnalysis..CovidVaccinations vac
	On dea.location = vac.location  
	and dea.date = vac.date  
where dea.continent is not null
 -- order by date 


-- Create db in CovidAnalysis 
USE CovidAnalysis;
GO
CREATE OR ALTER VIEW dbo.PercentPopulationVaccinated
AS
SELECT *
FROM master.dbo.PercentPopulationVaccinated;
GO

Select * From PercentPopulationVaccinated


