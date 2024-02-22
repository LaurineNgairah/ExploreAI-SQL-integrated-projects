SELECT * FROM md_water_services.project_progress;
-- Q1
Select  Count(Improvement)
From project_progress
Where Improvement like 'Install UV%';

-- Q2
With Q2 as (SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results,
CASE 
WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
WHEN water_source.type_of_water_source = 'river' THEN 'Drill Well'
WHEN water_source.type_of_water_source = 'shared_tap' AND time_in_queue >= 30 THEN CONCAT("Install ", FLOOR(time_in_queue/30), " taps nearby")
WHEN water_source.type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'
ELSE null
End as Improvement 
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1                                     
AND (                                                      
results != 'Clean'
OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
OR ( water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
)AND well_pollution.results != "Clean")

Select *
From Q2;

-- AND well_pollution.results != "Clean" to the well CASE statement;
-- Add AND combined_analysis_table.results != "Clean" to the well CASE statement.


-- Q3
Select Province,
count(Source_type) as count_source
From project_progress
Where Source_type = 'river'
Group by Province
Order by count_source; 

-- Q5
-- In progress
select
    province,
    town,
    count(source_type) as source_count
    from
    project_progress
    where source_type = "shared_tap"
    group by province,town
    order by source_count desc;
    
    -- Or
    
Create view shared_tap_improved as (SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results,
CASE 
WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
WHEN water_source.type_of_water_source = 'river' THEN 'Drill Well'
WHEN water_source.type_of_water_source = 'shared_tap' AND time_in_queue >= 30 THEN  FLOOR(time_in_queue/30)
ELSE null
End as Improvement 
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1                                     
AND (                                                      
results != 'Clean'
OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
OR ( water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
));

SELECT town_name, 
       count(Improvement) as Improvement
FROM shared_tap_improved
WHERE type_of_water_source = 'shared_tap'
GROUP BY   town_name
ORDER BY Improvement DESC;


-- Q7
WITH Town_Percentage AS (
    SELECT
        town_name,
        (SUM(CASE WHEN source_type = 'River' THEN people_served ELSE 0 END) / SUM(people_served)) * 100 AS percentage
    FROM
        combined_analysis_table
    WHERE
        province_name = 'Amanzi'
    GROUP BY
        town_name
)
SELECT
    town_name,
    MAX(percentage) AS max_percentage
FROM
    Town_Percentage
GROUP BY
    town_name
    Order by max_percentage Desc;
    
-- Q8
select
province_name,
town_name,
sum(tap_in_home + tap_in_home_broken) as pct_sum
from
town_aggregated_water_access
Where province_name IN ( 'Kilimani', 'Hawassa', 'Sokoto', 'Akatsi')
group by province_name,town_name
Having sum(tap_in_home + tap_in_home_broken) > 50
order by province_name;
-- Q10
SELECT
project_progress.Project_id, 
project_progress.Town, 
project_progress.Province, 
project_progress.Source_type, 
project_progress.Improvement,
Water_source.number_of_people_served,
RANK() OVER(PARTITION BY Province ORDER BY number_of_people_served)
FROM  project_progress 
JOIN water_source 
ON water_source.source_id = project_progress.source_id
WHERE Improvement = "Drill Well"
ORDER BY Province DESC, number_of_people_served