-- Total Cases in each country at every month

SELECT location, DATENAME(MONTH, date) as month, year(date) as year, SUM(new_cases) as Total_New_Cases
FROM [Covid 2022 Project]..[Covid Deaths]
WHERE continent is not null
GROUP BY LOCATION,month(date), year(date), datename(month, date)
ORDER BY location, year(date), month(date)

-- When was maximum new cases registered in each coutry? 

WITH Total_Cases_Per_Month as (

SELECT location, DATENAME(MONTH, date) as month, year(date) as year, SUM(new_cases) as Total_New_Cases
FROM [Covid 2022 Project]..[Covid Deaths]
WHERE continent is not null
GROUP BY LOCATION,month(date), year(date), datename(month, date)

),

Maximum_Cases as (SELECT location, MAX(Total_New_Cases) as Maximum_Cases
FROM Total_Cases_Per_Month
GROUP BY location )

SELECT a.location, b.month, b.year, a.Maximum_Cases
FROM Maximum_Cases a
JOIN Total_Cases_Per_Month b
ON a.location=b.location AND a.Maximum_Cases=b.Total_New_Cases

-- Total Cases as a percentage of Population

SELECT location, population as total_population, sum(CONVERT(int, new_cases)) as total_cases, round((sum(CONVERT(int, new_cases))/population)*100,3) as Population_Infected
FROM [Covid 2022 Project]..[Covid Deaths]
WHERE continent is not null
GROUP BY location, population
ORDER BY 4 DESC

-- Death Rate as a percent of infected population ordered by number of deaths

SELECT location, sum(new_cases) as total_cases, round(sum(new_cases)/population*100,3) as Infection_rate_population,  sum(convert(int,new_deaths)) as total_deaths, round(sum(convert(int, new_deaths))/sum(new_cases)*100,3) as Death_Rate_Infected
FROM [Covid 2022 Project]..[Covid Deaths]
WHERE continent is not null
GROUP BY location, population
ORDER BY 4 DESC

-- Percent of Infected Hospitalized and Admitted in ICU

WITH hospital_icu_data as (SELECT location, sum(new_cases) as total_cases, sum(convert(int,hosp_patients)) as hospitalized_patients, sum(convert(int,icu_patients)) as icu_admitted
FROM [Covid 2022 Project]..[Covid Deaths]
WHERE continent is not null and hosp_patients is not null and icu_patients is not null
GROUP BY location )

SELECT location, total_cases, hospitalized_patients, round(hospitalized_patients/total_cases*100,3) as rate_of_hospitalization, icu_admitted, round(icu_admitted/total_cases*100,3) as rate_of_icu
FROM hospital_icu_data
ORDER BY 6 DESC

-- Covid Infection and Death split by Continent

SELECT continent, sum(new_cases) as total_cases, sum(convert(int,new_deaths)) as total_deaths
FROM [Covid 2022 Project]..[Covid Deaths]
WHERE continent is not null
GROUP BY continent
ORDER BY 1 ASC

-- Covid month by month increase for each country

SELECT location, DATENAME(MONTH, date) as month, year(date) as year, sum(new_cases) as Total_New_Cases , case when lag(sum(new_cases)) over (partition by location order by year(date), month(date))! =0 and sum(new_cases) != 0 then round((sum(new_cases)/lag(sum(new_cases)) over (partition by location order by year(date), month(date)))-1,3)*100 else 0 end as increase_from_prev_month
FROM [Covid 2022 Project]..[Covid Deaths]
WHERE continent is not null and new_cases is not null
GROUP BY location, DATENAME(MONTH, date), year(date), month(date)
ORDER BY location, year(date),month(date)

-- Percentage of population Vaccinated

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
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From [Covid 2022 Project]..[Covid Deaths] dea
Join [Covid 2022 Project]..[Covid Vaccination] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select Continent, Location, concat(datename(month,date)+',',year(date)) as Date, (RollingPeopleVaccinated/Population)*100 as population_Vaccinated
From #PercentPopulationVaccinated
ORDER BY 1,2







