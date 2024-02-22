-- view auditor_report column location_id and type_of_water_source

Select
location_id,
true_water_source_score
From auditor_report;


-- join visits and auditor_report to view visits.record_id
Select
ar.location_id,
ar.true_water_source_score,
v.record_id
From auditor_report as ar
Join visits as v
on ar.location_id = v.location_id;


-- join auditor_report, visits, water_quality table to view the subjective_quality_score
Select
ar.location_id,
ar.true_water_source_score,
v.record_id,
wq.subjective_quality_score
From auditor_report as ar
Join visits as v
on ar.location_id = v.location_id
Join water_quality as wq
on v.record_id = wq.record_id;

-- Dropping location_id, leave record_id and rename the scores to surveyor_score and auditor_score to make it clear which scores
-- we're looking at in the results set and Limit 10000. 

Select 
ar.true_water_source_score as auditor_score,
v.record_id,
wq.subjective_quality_score as surveyor_score
From auditor_report as ar
Join visits as v
on ar.location_id = v.location_id
Join water_quality as wq
on v.record_id = wq.record_id;


-- check if the auditor's and exployees' scores agree. You got 2505 rows right?. 
-- The column alias does not work on the where clause
Select 
ar.true_water_source_score as auditor_score,
v.record_id,
wq.subjective_quality_score as surveyor_score
From auditor_report as ar
Join visits as v
on ar.location_id = v.location_id
Join water_quality as wq
on v.record_id = wq.record_id
where ar.true_water_source_score = wq.subjective_quality_score;

-- removing duplicates by setting the visits.visit_count = 1 in the WHERE clause.
-- We get 1518 rows 
Select 
ar.true_water_source_score as auditor_score,
v.record_id,
wq.subjective_quality_score as surveyor_score
From auditor_report as ar
Join visits as v
on ar.location_id = v.location_id
Join water_quality as wq
on v.record_id = wq.record_id
where ar.true_water_source_score = wq.subjective_quality_score 
and v.visit_count = 1;

-- But that means that 102 records are incorrect. So let's look at those. 
-- You can do it by adding one character in the last query!
-- We are trying to find the subjective/employees scores that are not matching with the auditors scores
Select 
ar.true_water_source_score as auditor_score,
v.record_id,
wq.subjective_quality_score as surveyor_score
From auditor_report as ar
Join visits as v
on ar.location_id = v.location_id
Join water_quality as wq
on v.record_id = wq.record_id
where ar.true_water_source_score != wq.subjective_quality_score 
and v.visit_count = 1;

-- So, to do this, we need to grab the type_of_water_source column from the water_source table and call 
-- it survey_source, using the source_id column to JOIN. 
-- Also select the type_of_water_source from the auditor_report table, and call it auditor_source.

Select 
ar.true_water_source_score as auditor_score,
v.record_id,
wq.subjective_quality_score as surveyor_score,
ar.type_of_water_source as auditor_source,
ws.type_of_water_source as survey_source
From auditor_report as ar
Join visits as v
on ar.location_id = v.location_id
Join water_quality as wq
on v.record_id = wq.record_id
Join water_source as ws
on ws.source_id = v.source_id
where ar.true_water_source_score != wq.subjective_quality_score 
and v.visit_count = 1;

-- Once you're done, remove the columns and JOIN statement for water_sources again.
-- The employees are the source of the errors, so let's JOIN the assigned_employee_id for all the people
-- on our list from the visits we join the employee data table to our query.
Select 
ar.true_water_source_score as auditor_score,
v.record_id,
wq.subjective_quality_score as surveyor_score,
e.employee_name as Employee_Incorrect_Scores
From auditor_report as ar
Join visits as v
on ar.location_id = v.location_id
Join water_quality as wq
on v.record_id = wq.record_id
Join employee as e
on e.assigned_employee_id = v.assigned_employee_id
where ar.true_water_source_score != wq.subjective_quality_score 
and v.visit_count = 1;

-- Well this query is massive and complex, so maybe it is a good idea to save this as a CTE, 
-- so when we do more analysis, we can just call that CTE like it was a table. 
-- Call it something like Incorrect_records. Once you are done, check if this query 
-- SELECT * FROM Incorrect_records, gets the same table back.

With Incorrect_records
as (Select 
ar.true_water_source_score as auditor_score,
v.record_id,
wq.subjective_quality_score as surveyor_score,
e.employee_name as Employee_Incorrect_Scores
From auditor_report as ar
Join visits as v
on ar.location_id = v.location_id
Join water_quality as wq
on v.record_id = wq.record_id
Join employee as e
on e.assigned_employee_id = v.assigned_employee_id
where ar.true_water_source_score != wq.subjective_quality_score 
and v.visit_count = 1)
Select *
From Incorrect_records;

-- Let's first get a unique list of employees from this table.
With Incorrect_records
as (Select 
ar.true_water_source_score as auditor_score,
v.record_id,
wq.subjective_quality_score as surveyor_score,
e.employee_name as Employee_Incorrect_Scores
From auditor_report as ar
Join visits as v
on ar.location_id = v.location_id
Join water_quality as wq
on v.record_id = wq.record_id
Join employee as e
on e.assigned_employee_id = v.assigned_employee_id
where ar.true_water_source_score != wq.subjective_quality_score 
and v.visit_count = 1)
Select distinct Employee_Incorrect_Scores
From Incorrect_records;

-- Next, let's try to calculate how many mistakes each employee made as error_count. 
-- So basically we want to count how many times their name is in 
-- Incorrect_records list, and then group them by name,


With Incorrect_records
as (Select 
ar.true_water_source_score as auditor_score,
v.record_id,
wq.subjective_quality_score as surveyor_score,
e.employee_name as Employee_Incorrect_Scores
From auditor_report as ar
Join visits as v
on ar.location_id = v.location_id
Join water_quality as wq
on v.record_id = wq.record_id
Join employee as e
on e.assigned_employee_id = v.assigned_employee_id
where ar.true_water_source_score != wq.subjective_quality_score 
and v.visit_count = 1)
Select  Employee_Incorrect_Scores,
Count(Employee_Incorrect_Scores) as error_count
From Incorrect_records
Group by Employee_Incorrect_Scores;

-- we need to calculate the average number of mistakes employees made.

With error_count as (With Incorrect_records
as (Select 
ar.true_water_source_score as auditor_score,
v.record_id,
wq.subjective_quality_score as surveyor_score,
e.employee_name as Employee_Incorrect_Scores
From auditor_report as ar
Join visits as v
on ar.location_id = v.location_id
Join water_quality as wq
on v.record_id = wq.record_id
Join employee as e
on e.assigned_employee_id = v.assigned_employee_id
where ar.true_water_source_score != wq.subjective_quality_score 
and v.visit_count = 1)
Select  Employee_Incorrect_Scores,
Count(Employee_Incorrect_Scores) as number_of_mistakes
From Incorrect_records
Group by Employee_Incorrect_Scores)
SELECT
AVG(number_of_mistakes) as avg_error_count_per_empl
FROM error_count;

-- to compare each employee's error_count with avg_error_count_per_empl as suspect_list.
-- create view 
CREATE VIEW Incorrect_records AS (
SELECT
auditor_report.location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS employee_score,
auditor_report.statements AS statements
FROM auditor_report
JOIN visits
ON auditor_report.location_id = visits.location_id
JOIN water_quality AS wq
ON visits.record_id = wq.record_id
JOIN employee
ON employee.assigned_employee_id = visits.assigned_employee_id
WHERE visits.visit_count =1
AND auditor_report.true_water_source_score != wq.subjective_quality_score);


-- now we compare each employee's error_count with avg_error_count_per_empl as suspect_list 
-- referencing it to view created earlier
WITH error_count AS (
    SELECT
        employee_name,
        COUNT(*) AS number_of_mistakes
    FROM Incorrect_records
    GROUP BY employee_name
    ORDER BY number_of_mistakes DESC
)

SELECT
	employee_name,
    number_of_mistakes
FROM error_count
WHERE (number_of_mistakes) > (SELECT AVG(number_of_mistakes) FROM error_count);

-- we convert the query error_count, we made earlier, into a CTE.
WITH error_count  -- This CTE calculates the number of mistakes each employee made
AS (SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records

-- Incorrect_records is a view that joins the audit report to the database
-- for records where the auditor and employees scores are different


GROUP BY
employee_name)
-- Query
SELECT * FROM error_count;

-- Now calculate the average of the number_of_mistakes in error_count. You should get a single value.

WITH error_count  -- This CTE calculates the number of mistakes each employee made
AS (SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records

-- Incorrect_records is a view that joins the audit report to the database
-- for records where the auditor and employees scores are different


GROUP BY
employee_name)
-- Query
SELECT avg(number_of_mistakes) as avg_number_of_mistakes
FROM error_count;

-- To find the employees who made more mistakes than the average person, we need the employee's names, 
-- the number of mistakes each one made, and filter the employees with an above-average number of mistakes.

WITH error_count  
AS (SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY
employee_name)
SELECT 
employee_name,
number_of_mistakes
FROM error_count 
Where number_of_mistakes > (SELECT avg(number_of_mistakes) -- instead of using 6
FROM error_count);

-- convert the suspect_list to a CTE, so we can use it to filter the records from these four employees.
WITH error_count AS (
    SELECT
        employee_name,
        COUNT(*) AS number_of_mistakes
    FROM Incorrect_records
    GROUP BY employee_name
    ORDER BY number_of_mistakes DESC
),
suspect_list AS(
	SELECT
	employee_name,
    number_of_mistakes
FROM error_count
WHERE (number_of_mistakes) > (SELECT AVG(number_of_mistakes) FROM error_count)
)

SELECT employee_name,
Number_of_mistakes
FROM suspect_list;


-- add the statements column to the Incorrect_records CTE. 
-- Then pull up all of the records where the employee_name is in the suspect list
WITH error_count AS (
    SELECT
        employee_name,
        COUNT(*) AS number_of_mistakes
    FROM Incorrect_records 
    GROUP BY employee_name
    ORDER BY number_of_mistakes DESC
),
suspect_list AS(
	SELECT
	employee_name,
    number_of_mistakes
FROM error_count
WHERE (number_of_mistakes) > (SELECT AVG(number_of_mistakes) FROM error_count)
)

SELECT statements,location_id,employee_name
FROM Incorrect_records
WHERE
employee_name IN (SELECT employee_name FROM suspect_list);


-- Filter the records that refer to "cash".
WITH error_count AS (
    SELECT
        employee_name,
        COUNT(*) AS number_of_mistakes
    FROM Incorrect_records 
    GROUP BY employee_name
    ORDER BY number_of_mistakes DESC
),
suspect_list AS(
	SELECT
	employee_name,
    number_of_mistakes
FROM error_count
WHERE (number_of_mistakes) > (SELECT AVG(number_of_mistakes) FROM error_count)
)

SELECT statements,location_id,employee_name
FROM Incorrect_records
WHERE
statements like "%cash%";

-- Check if there are any employees in the Incorrect_records table with statements mentioning "cash" 
-- that are not in our suspect list. 
-- This should be as simple as adding one word.

WITH error_count AS (
    SELECT
        employee_name,
        COUNT(*) AS number_of_mistakes
    FROM Incorrect_records 
    GROUP BY employee_name
    ORDER BY number_of_mistakes DESC
),
suspect_list AS(
	SELECT
	employee_name,
    number_of_mistakes
FROM error_count
WHERE (number_of_mistakes) > (SELECT AVG(number_of_mistakes) FROM error_count)
)
SELECT statements,location_id,employee_name
FROM Incorrect_records
WHERE statements LIKE "%cash%" and 
employee_name NOT IN (SELECT employee_name FROM suspect_list);

