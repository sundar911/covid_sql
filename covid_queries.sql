SELECT * 
FROM IHDS_DS_17..covid_deaths_1
ORDER BY 3,4

-- subset of data we want to work with
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM IHDS_DS_17..covid_deaths_1
order by 1,2

-- case to death ratio
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage 
FROM IHDS_DS_17..covid_deaths_1
order by 1,2

-- for sri lanka
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage 
FROM IHDS_DS_17..covid_deaths_1
where location like '%lanka%'
order by 1,2

-- covid in population for sri lanka
SELECT location, date, total_cases, population, (total_cases/population)*100 as perc_pop 
FROM IHDS_DS_17..covid_deaths_1
where location like '%lanka%'
order by 1,2

-- covid in population for india
SELECT location, date, total_cases, population, (total_cases/population)*100 as perc_pop 
FROM IHDS_DS_17..covid_deaths_1
where location like '%india%'
order by 1,2

-- most affected countries wrt infection rate
SELECT location, max(total_cases) as cases, population, max((total_cases/population))*100 as infection_percentage
from IHDS_DS_17..covid_deaths_1
GROUP by location, population
order by infection_percentage DESC

-- most affected countries wrt fatality rate
SELECT location, max(total_deaths) as cases, max((total_deaths/population))*100 as fatality_percentage
from IHDS_DS_17..covid_deaths_1
where continent is not NULL
GROUP by location
order by fatality_percentage DESC

-- ranking countries by number of deaths
SELECT location, max(total_deaths) as Deaths, population
from IHDS_DS_17..covid_deaths_1
where continent is not NULL
GROUP by location, population
order by Deaths DESC



--analyzing by continent

-- most affected continents wrt infection rate
SELECT continent, max(total_cases) as cases, population, max((total_cases/population))*100 as infection_percentage
from IHDS_DS_17..covid_deaths_1
where continent is NOT NULL
GROUP by continent, population
order by infection_percentage DESC

-- most affected continents wrt fatality rate
SELECT continent, max(total_deaths) as cases, max((total_deaths/population))*100 as fatality_percentage
from IHDS_DS_17..covid_deaths_1
where continent is NOT NULL
GROUP by continent
order by fatality_percentage DESC

-- ranking continents by number of deaths
SELECT continent, max(total_deaths) as Deaths
from IHDS_DS_17..covid_deaths_1
where continent is not NULL
GROUP by continent
order by Deaths DESC

-- GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From IHDS_DS_17..covid_deaths_1
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From IHDS_DS_17..covid_deaths_1 dea
Join IHDS_DS_17..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From IHDS_DS_17..covid_deaths_1 dea
Join IHDS_DS_17..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

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
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From IHDS_DS_17..covid_deaths_1 dea
Join IHDS_DS_17..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From IHDS_DS_17..covid_deaths_1 dea
Join IHDS_DS_17..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 