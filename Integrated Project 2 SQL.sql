-- We have to update the database again with these email addresses, so before we do, let's use a SELECT query to get the format right, then use
-- UPDATE and SET to make the changes. Slide 5-7

SET SQL_SAFE_UPDATES=0;
UPDATE md_water_services.employee
SET email = Concat(Lower(replace(employee_name, " ", ".")), '@ndogowater.gov');

-- Use TRIM() to write a SELECT query again, make sure we get the string without the space, and then UPDATE the record like you just did for the
-- emails. If you need more information about TRIM(), Google "TRIM documentation MySQL". slide 7-8

SELECT
LENGTH(phone_number)
FROM
employee;

Select
Length(Trim(phone_number))
From employee;

SET SQL_SAFE_UPDATES=0;
Update  md_water_services.employee
Set  phone_number = TRIM(phone_number);


-- Use the employee table to count how many of our employees live in each town. Think carefully about what function we should use and how we
-- should aggregate the data. Slide 8-9

Select
town_name,
count(employee_name)
From employee
Group by town_name;

-- So let's use the database to get the
-- employee_ids and use those to get the names, email and phone numbers of the three field surveyors with the most location visits.
-- Let's first look at the number of records each employee collected. So find the correct table, figure out what function to use and how to group, order
-- and limit the results to only see the top 3 employee_ids with the highest number of locations visited.

Select 
assigned_employee_id,
Count(location_id) as number_of_visits
From visits 
Group by assigned_employee_id
Order by  number_of_visits desc
Limit 3;


-- Make a note of the top 3 assigned_employee_id and use them to create a query that looks up the employee's info. Since you're a pro at finding
-- stuff in a database now, you can figure this one out. You should have a column of names, email addresses and phone numbers for our top dogs.
Select *
From  employee
Where assigned_employee_id IN (1, 30, 34);

-- Create a query that counts the number of records per 

SELECT town_name, 
COUNT(*) AS record_count
FROM location
GROUP BY town_name;

-- Now count the records per province.
SELECT province_name, 
COUNT(*) AS record_count
FROM location
GROUP BY province_name;

-- Create a result set showing: 
-- province_name
-- town_name
-- An aggregated count of records for each town (consider naming this records_per_town).
-- Ensure your data is grouped by both province_name and town_name.
-- Order your results primarily by province_name. Within each province, further sort the towns by their record counts in descending order.

Select province_name,
town_name,auditor_reportauditor_report
count(town_name) as records_per_town
From location
Group by province_name, town_name
Order by province_name, records_per_town Desc;

