Select *
From [covid-19]..CovidDeaths



--	Select *
--From [covid-19]..CovidVaccinations

Select Location, date, total_cases, new_cases, total_deaths, population
From [covid-19]..CovidDeaths
order by 1,2

--Total cases vs Total Deaths

SELECT 
    Location,
    date,
    TRY_CAST(total_cases AS FLOAT) AS total_cases,
    TRY_CAST(total_deaths AS FLOAT) AS total_deaths,
    TRY_CAST(total_deaths AS FLOAT) / NULLIF(TRY_CAST(total_cases AS FLOAT), 0) * 100 AS death_rate
FROM [covid-19]..CovidDeaths
Where Location like '%kingdom%'
ORDER BY Location, date;

--Total cases vs Population
SELECT 
    Location,
    date,
    TRY_CAST(total_cases AS FLOAT) AS total_cases,
    Population,
    (TRY_CAST(total_cases AS FLOAT) / population) * 100 AS PercentagePopulationInfected
FROM [covid-19]..CovidDeaths
Where Location like '%kingdom%'
ORDER BY Location, date;


---Countries with the highest infection rate compared to population
SELECT 
    Location,
    population,
    MAX(TRY_CAST(total_cases AS FLOAT)) AS HighestInfectionCount,
    MAX((TRY_CAST(total_cases AS FLOAT) / NULLIF(TRY_CAST(population AS FLOAT),0))) * 100 AS PercentagePopulationInfected
FROM [covid-19]..CovidDeaths
--Where Location like '%kingdom%'
Group by location, population
ORDER BY PercentagePopulationInfected desc;


--Countries with the highest Death Count per population
SELECT
	Location,
	MAX(TRY_CAST(total_deaths AS FLOAT)) AS TotalDeathCount
FROM [covid-19]..CovidDeaths
Group by location
Order by TotalDeathCount desc

--Continent with the highest Death Count per population
SELECT
	continent,
	MAX(TRY_CAST(total_deaths AS FLOAT)) AS TotalDeathCount
FROM [covid-19]..CovidDeaths
Group by continent
Order by TotalDeathCount desc

---Global numbers

SELECT 
    --date,
    SUM(TRY_CAST(new_cases AS FLOAT)) AS total_cases,
    SUM(TRY_CAST(new_deaths AS FLOAT)) AS total_deaths,
    SUM(TRY_CAST(new_deaths AS FLOAT)) / SUM(TRY_CAST(new_cases AS FLOAT)) * 100 AS death_rate
FROM [covid-19]..CovidDeaths
where continent is not null
--Group by date
ORDER BY 1,2;


--- Joining both tables together based on location and date

SELECT *
FROM [covid-19]..CovidDeaths dea
JOIN  CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date


--Total Population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations
FROM [covid-19]..CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
ORDER BY 2,3

--New Vaccination per day(Rolling People Vaccinated)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(TRY_CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
	FROM [covid-19]..CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
ORDER BY 2,3


--- Using CTE
WITH PopvsVac(Continent, Location, Date, Population, New_vacciantions, RollingPeopleVaccinated)
AS
( SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(TRY_CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
	FROM [covid-19]..CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated)/ NULLIF(TRY_CAST(Population AS FLOAT),0) * 100
FROM PopvsVac


---Using Temp Table

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)



Insert Into #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(TRY_CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
	FROM [covid-19]..CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
--ORDER BY 2,3


SELECT *, (RollingPeopleVaccinated)/ NULLIF(TRY_CAST(Population AS FLOAT),0) * 100
FROM #PercentPopulationVaccinated



----Creating view to store data for visualization
Create View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(TRY_CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
	FROM [covid-19]..CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
--ORDER BY 2,3
