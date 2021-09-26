/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


Select *
From [PortfolioProject].[dbo].[CovidDeaths]
Order by 3,4

--Select *
--From [PortfolioProject].[dbo].[CovidVaccinations]
--Order by 3,4

-- Select and Where clause 
Select location, date, total_cases, new_cases, total_deaths, population
From [PortfolioProject].[dbo].[CovidDeaths]
Where location ='United Kingdom'
and total_deaths >=1 
Order by 1,2
 
 --Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From [PortfolioProject].[dbo].[CovidDeaths]
Where continent is not null 
order by 1,2

-- % of deaths (total cases vs total deaths)
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [PortfolioProject].[dbo].[CovidDeaths]
Where location like '%Kingdom%'
and continent is not null 
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From [PortfolioProject].[dbo].[CovidDeaths]
Where location like '%Kingdom%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From [PortfolioProject].[dbo].[CovidDeaths]
Group by Location, Population
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per Population as of 21.09.2021

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [PortfolioProject].[dbo].[CovidDeaths]
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [PortfolioProject].[dbo].[CovidDeaths]
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From [PortfolioProject].[dbo].[CovidDeaths]
where continent is not null 
order by 1,2

-- Total Population vs Vaccinations
-- Joining Covid.Deaths and Covid.Vaccinations tables

Select*
From [PortfolioProject].[dbo].[CovidDeaths] dea
join [PortfolioProject].[dbo].[CovidVaccinations] vacc
on dea.location = vacc.location
and dea.date = vacc.date

--Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(CONVERT(int,vacc.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From [PortfolioProject].[dbo].[CovidDeaths] dea
Join [PortfolioProject].[dbo].[CovidVaccinations] vacc
	On dea.location = vacc.location
	and dea.date = vacc.date
where dea.continent is not null 
order by 2,3

--Oh no! Got the following error when running the previous query:
--ORDER BY list of RANGE window frame has total size of 1020 bytes. Largest size supported is 900 bytes.

--Solution:

ALTER TABLE [PortfolioProject].[dbo].[CovidDeaths]
ALTER COLUMN location nvarchar(150)

-- Using CTE to perform Calculation on Partition By in previous query

With Population_vs_Vaccinations (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(CONVERT(int,vacc.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From [PortfolioProject].[dbo].[CovidDeaths] dea
Join [PortfolioProject].[dbo].[CovidVaccinations] vacc
	On dea.location = vacc.location
	and dea.date = vacc.date
where dea.continent is not null 
--order by 2,3
)
Select *
From Population_vs_Vaccinations
where location = 'United Kingdom'
and New_Vaccinations is not null

--We can see that the the first vaccine in the UK was given on 11.01.21 as per result of previoues query

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(CONVERT(int,vacc.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From [PortfolioProject].[dbo].[CovidDeaths] dea
Join [PortfolioProject].[dbo].[CovidVaccinations] vacc
	On dea.location = vacc.location
	and dea.date = vacc.date
where dea.continent is not null 
--order by 2,3

Select *
From #PercentPopulationVaccinated
where location = 'United Kingdom'
and New_Vaccinations is not null

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(CONVERT(int,vacc.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From [PortfolioProject].[dbo].[CovidDeaths] dea
Join [PortfolioProject].[dbo].[CovidVaccinations] vacc
	On dea.location = vacc.location
	and dea.date = vacc.date
where dea.continent is not null 