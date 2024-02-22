
-- So first, grab the location_id and true_water_source_score columns from auditor_report.
SELECT
    location_id,
    true_water_source_score
FROM
  auditor_report;
  
  
-- Now, we join the visits table to the auditor_report table. Make sure to grab subjective_quality_score, record_id and location_id.
  
SELECT
    wq.record_id,
    wq.subjective_quality_score AS water_quality_score,
	ar.location_id as audit_location,
    v.location_id as visit_location
FROM
    water_quality AS wq
JOIN
    visits AS v ON wq.record_id = v.record_id
JOIN
    auditor_report AS ar ON v.location_id = ar.location_id;
    
    -- or
SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score,
visits.location_id AS visit_location,
visits.record_id
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id;
    
-- Now that we have the record_id for each location, our next step is to retrieve the corresponding scores from the water_quality table. We
-- are particularly interested in the subjective_quality_score. To do this, we'll JOIN the visits table and the water_quality table, using the
-- record_id as the connecting key.
SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score,
visits.location_id AS visit_location,
visits.record_id,
water_quality.subjective_quality_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN water_quality
ON water_quality.record_id = visits.record_id;

-- It doesn't matter if your columns are in a different format, because we are about to clean this up a bit. Since it is a duplicate, we can drop one of
-- the location_id columns. Let's leave record_id and rename the scores to surveyor_score and auditor_score to make it clear which scores
-- we're looking at in the results set.

SELECT
auditor_report.location_id,
visits.record_id,
auditor_report.true_water_source_score as auditor_score,
water_quality.subjective_quality_score as surveyor_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN water_quality
ON water_quality.record_id = visits.record_id
LIMIT 10000;

-- We can have a WHERE clause and check if surveyor_score = auditor_score, or we can subtract the two 
-- scores and check if the result is 0.
SELECT
auditor_report.location_id,
visits.record_id,
auditor_report.true_water_source_score as auditor_score,
water_quality.subjective_quality_score as surveyor_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN water_quality
ON water_quality.record_id = visits.record_id
WHERE true_water_source_score = subjective_quality_score 
LIMIT 10000;

-- With the duplicates removed I now get 1518. What does this mean considering the auditor visited 1620 sites?
SELECT
auditor_report.location_id,
visits.record_id,
auditor_report.true_water_source_score as auditor_score,
water_quality.subjective_quality_score as surveyor_score,
water_quality.visit_count
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN water_quality
ON water_quality.record_id = visits.record_id
WHERE water_quality.visit_count = 1 and true_water_source_score = subjective_quality_score 
LIMIT 10000;

-- But that means that 102 records are incorrect. 
-- So let's look at those. You can do it by adding one character in the last query! 

SELECT
auditor_report.location_id,
visits.record_id,
auditor_report.true_water_source_score as auditor_score,
water_quality.subjective_quality_score as surveyor_score,
water_quality.visit_count
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN water_quality
ON water_quality.record_id = visits.record_id
WHERE water_quality.visit_count = 1 and true_water_source_score != subjective_quality_score 
LIMIT 10000;


-- So, to do this, we need to grab the type_of_water_source column from the water_source table and call it survey_source, using the
-- source_id column to JOIN. Also select the type_of_water_source from the auditor_report table, and call it auditor_source.

SELECT
auditor_report.location_id,
visits.record_id,
auditor_report.true_water_source_score as auditor_score,
water_quality.subjective_quality_score as surveyor_score,
water_source.type_of_water_source as survey_source,
auditor_report.type_of_water_source as auditor_source
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN water_quality
ON water_quality.record_id = visits.record_id
JOIN water_source
on water_source.source_id = visits.source_id
WHERE water_quality.visit_count = 1 and true_water_source_score != subjective_quality_score 
LIMIT 10000;


