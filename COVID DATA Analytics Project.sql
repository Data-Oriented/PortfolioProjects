SELECT * FROM Portfolio.coviddeaths

-- select data that we will be working with

SELECT location, date, total_cases, new_cases, total_deaths, population
from Portfolio.coviddeaths
order by 1,2

-- looking at Death % evolution in Canada

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as 'Death %'
from Portfolio.coviddeaths
where location like '%Canada%'
Order by 1,2

-- Looking at total population who got COVID

SELECT location, date, population, total_cases, (total_cases/population)*100 as 'Total Cases %'
from Portfolio.coviddeaths
where location like '%Canada%'
Order by 1,2

-- Looking at countries with highest infection rate compared to population
-- Use Group by Population and location since there are 2 consolidations
SELECT location, population, max(total_cases) as 'Highest Infection Count', Max((total_cases/population)*100) as '% of Population Infected'
from Portfolio.coviddeaths
Group by location, population
Order by 4 DESC

-- Showing countries with highest Death count per population
SELECT location, Max(cast((total_deaths) as SIGNED integer)) as 'Total Deaths Count'
from Portfolio.coviddeaths
where continent !=''
group by location
Order by 2 DESC

-- Group by continent

SELECT continent, sum(cast((new_cases) as SIGNED integer)) as Total_Cases, sum(cast((new_deaths) as SIGNED integer)) as Total_Deaths
from Portfolio.coviddeaths
where continent !=''
group by continent
Order by 3 DESC

-- Global Numbers

SELECT sum(cast((new_cases) as SIGNED integer)) as total_cases_count, sum(cast((new_deaths) as SIGNED integer)) as total_deaths_count, (sum(cast((new_deaths) as SIGNED integer))/ sum(cast((new_cases) as SIGNED integer)))*100 as 'Death %'
from Portfolio.coviddeaths
where continent !=''
-- group by continent
-- Order by 3 DESC

-- joining 2 tables (COVID DEATHS & COVID Vaccinations)
select *
from `Portfolio`.`coviddeaths`
join `Portfolio`.`covidvaccinations` on Portfolio.covidvaccinations.location = Portfolio.coviddeaths.location AND Portfolio.covidvaccinations.date=Portfolio.coviddeaths.date

-- Looking at vaccination progression per country per date (Rolling count)
-- I used Cast to convert the fileds to integer and Partition
select dea.location, dea.date, cast((dea.population) as signed integer) as Total_Poplation, cast(dea.new_vaccinations as signed integer) as NEW_Vac, sum(cast((vac.new_vaccinations) as signed integer)) over (partition by dea.location order by dea.location, dea.date)
from Portfolio.coviddeaths dea
join Portfolio.covidvaccinations vac on dea.location = vac.location AND dea.date=vac.date
where dea.continent !=''
Order by 2, 3 ASC

-- Looking at total vaccinated by country

select dea.continent, dea.location, dea.date, cast((dea.population) as signed integer) as Total_Poplation, dea.new_vaccinations, sum(cast((vac.new_vaccinations) as signed integer)) over (partition by dea.location order by dea.location, dea.date) as Rolling_Vaccination
from Portfolio.coviddeaths dea
join Portfolio.covidvaccinations vac on dea.location = vac.location AND dea.date=vac.date
where dea.continent !=''
-- Group by dea.date
Order by 2, 3 ASC

-- Use CTE

with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_Vaccination)
as
(
select dea.continent, dea.location, dea.date, cast((dea.population) as signed integer) as Total_Poplation, dea.new_vaccinations, sum(cast((vac.new_vaccinations) as signed integer)) over (partition by dea.location order by dea.location, dea.date) as Rolling_Vaccination
from Portfolio.coviddeaths dea
join Portfolio.covidvaccinations vac on dea.location = vac.location AND dea.date=vac.date
where dea.continent !=''
-- Group by dea.date
Order by 2, 3 ASC
)
select *, (Rolling_Vaccination/Population)*100
from PopvsVac

-- USE TEMP TABLE
-- use of case to select only integer and replace empty cells with 0
-- use join to link the 2 tables


DROP TABLE IF EXISTS portfolio.PercentPopulationVacinated;
CREATE TABLE portfolio.PercentPopulationVacinated (
  Continent varchar(255),
  Location varchar(255),
  Date datetime,
  Population integer,
  New_Vaccinations integer,
  Rolling_Vaccination integer
);

INSERT INTO portfolio.PercentPopulationVacinated
SELECT dea.continent, 
       dea.location, 
       dea.date, 
       dea.population, 
       case 
         when vac.new_vaccinations regexp '^[0-9]+$' 
         then cast(vac.new_vaccinations as signed integer)
         else 0 
       end as New_Vaccinations,
       sum(case 
         when vac.new_vaccinations regexp '^[0-9]+$' 
         then cast(vac.new_vaccinations as signed integer)
         else 0 
       end) over (partition by location order by location, dea.date) as Rolling_Vaccination
FROM Portfolio.coviddeaths dea
JOIN Portfolio.covidvaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent != ''
ORDER BY dea.location, dea.date

select
from portfolio.PercentPopulationVacinated

-- Creating a view for Percent Population Vaccinated
Drop view if exists PercentPopulationVacinated_New;
create view PercentPopulationVacinated_New as
SELECT dea.continent, 
       dea.location, 
       dea.date, 
       dea.population, 
       case 
         when vac.new_vaccinations regexp '^[0-9]+$' 
         then cast(vac.new_vaccinations as signed integer)
         else 0 
       end as New_Vaccinations,
       sum(case 
         when vac.new_vaccinations regexp '^[0-9]+$' 
         then cast(vac.new_vaccinations as signed integer)
         else 0 
       end) over (partition by location order by location, dea.date) as Rolling_Vaccination
FROM Portfolio.coviddeaths dea
JOIN Portfolio.covidvaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent != ''
-- ORDER BY dea.location, dea.date


