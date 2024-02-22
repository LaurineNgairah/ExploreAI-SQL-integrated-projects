-- Start by joining location to visits.

Select
l.location_id,
l.province_name,
l.town_name,
v.visit_count
From 
location as l
Join visits as v
on l.location_id = v.location_id;

-- Now, we can join the water_source table on the key shared between water_source and visits.

Select
l.location_id,
l.province_name,
l.town_name,
v.visit_count,
ws.type_of_water_source,
ws.number_of_people_served
From 
location as l
Join visits as v
on l.location_id = v.location_id
Join water_source as ws
on v.source_id = ws.source_id
WHERE v.location_id = 'AkHa00103';


-- Remove WHERE visits.location_id = 'AkHa00103' and add the visits.visit_count = 1 as a filter.
-- To have unique location Id rows 
Select
l.location_id,
l.province_name,
l.town_name,
v.visit_count,
ws.type_of_water_source,
ws.number_of_people_served
From 
location as l
Join visits as v
on l.location_id = v.location_id
Join water_source as ws
on v.source_id = ws.source_id
WHERE v.visit_count = 1;

-- remove the location_id and visit_count columns.
Select
l.province_name,
l.town_name,
ws.type_of_water_source,
ws.number_of_people_served
From 
location as l
Join visits as v
on l.location_id = v.location_id
Join water_source as ws
on v.source_id = ws.source_id
WHERE v.visit_count = 1;

-- Add the location_type column from location and time_in_queue from visits to our results set.
Select
l.province_name,
l.town_name,
ws.type_of_water_source,
ws.number_of_people_served,
location_type,
time_in_queue
From 
location as l
Join visits as v
on l.location_id = v.location_id
Join water_source as ws
on v.source_id = ws.source_id
WHERE v.visit_count = 1;

-- Last one! Now we need to grab the results from the well_pollution table.
-- This one is a bit trickier. The well_pollution table contained only data for well. 
-- If we just use JOIN, we will do an inner join, so that only records
-- that are in well_pollution AND visits will be joined. We have to use a LEFT JOIN to join theresults from the well_pollution table for well
-- sources, and will be NULL for all of the rest. Play around with the different JOIN operations to 
-- make sure you understand why we used LEFT JOIN.

SELECT
water_source.type_of_water_source,
location.town_name,
location.province_name,
location.location_type,
water_source.number_of_people_served,
visits.time_in_queue,
well_pollution.results
FROM
visits
LEFT JOIN    
well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN
location
ON location.location_id = visits.location_id
INNER JOIN
water_source
ON water_source.source_id = visits.source_id
WHERE
visits.visit_count = 1;

-- Create a view for the above query
-- An inner join returns only the matching data from both tables, 
-- A left join returns all data from the left table and matching data from the right table, with NULL values when there’s no mat

CREATE VIEW combined_analysis_table AS        -- This view assembles data from different tables into one to simplify analysis
SELECT
water_source.type_of_water_source AS source_type,
location.town_name,
location.province_name,
location.location_type,
water_source.number_of_people_served AS people_served,
visits.time_in_queue,
well_pollution.results
FROM
visits
LEFT JOIN                                           
well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN
location
ON location.location_id = visits.location_id
INNER JOIN
water_source
ON water_source.source_id = visits.source_id
WHERE
visits.visit_count = 1;

-- % of people served per type of water source 

WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
province_name,
SUM(people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;


-- to group by province first, then by town, so that the duplicate towns are distinct because they are in different towns.

WITH town_totals AS     -- This CTE calculates the population of each town
(          
						-- Since there are two Harare towns, we have to group by province_name and town_name
SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN                            -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY                            -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

-- Create a temporary table. When MySql is closed the table is lost. Run the query to create again
CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS
     
(          
						
SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN                            -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY                            -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;
 -- View the temporary table
Select *
From town_aggregated_water_access;

-- which town has the highest ratio of people who have taps, but have no running water? Amina in Amanzi Province
SELECT
province_name,
town_name,
ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) *

100,0) AS Pct_broken_taps

FROM
town_aggregated_water_access;

-- Project Progress Table

CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT
);

-- Project_progress_query
-- Left join returns all data from the left table and matching data from the right table with null values where there is no match
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1                                      -- This must always be true
AND (                                                      -- AND one of the following (OR) options must be true as well.
results != 'Clean'
OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
OR ( water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
);


-- Well Improvements
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results,
CASE 
WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
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
visits.visit_count = 1                                      -- This must always be true
AND (                                                      -- AND one of the following (OR) options must be true as well.
results != 'Clean'
OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
OR ( water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
);

-- Rivers:Add Drill well to the Improvements column for all river sources.

SELECT
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
);

-- Improvement for shared taps
SELECT
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
);

--  improvement of In-home taps broken
 SELECT
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
);

-- Create View as compiled table to store all the changes we have made.
Create View Compiled_Table as (
SELECT
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
));


-- Checking for null values in the improvement column
With Checking_null as 
(SELECT
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
))
Select *
From Checking_null
Where improvement = null;


-- Add the data to Project_progress using the view Compiled_table

Insert into project_progress
( source_id, Address, Town, Province, Source_type, Improvement)
Select 
source_id,
Address,
town_name,
province_name,
type_of_water_source,
Improvement
From compiled_table;

 