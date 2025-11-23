-- Query to retrieve all programs/courses offered by the school
-- This query provides a comprehensive list of available courses with their details

-- Basic query to get all active courses
SELECT
    course_code,
    course_name,
    college,
    CASE
        WHEN grade_requirement IS NOT NULL THEN CONCAT(grade_requirement, '%')
        ELSE 'No required grade'
    END as grade_requirement,
    description
FROM courses
WHERE is_active = true
ORDER BY college, course_name;

-- Query to get courses grouped by college
SELECT
    college,
    COUNT(*) as total_programs,
    STRING_AGG(course_name, ', ') as programs
FROM courses
WHERE is_active = true
GROUP BY college
ORDER BY college;

-- Query to get courses with grade requirements
SELECT
    course_code,
    course_name,
    college,
    grade_requirement,
    description
FROM courses
WHERE is_active = true
AND grade_requirement IS NOT NULL
ORDER BY grade_requirement DESC, course_name;

-- Query to get undergraduate programs only (excluding graduate programs)
SELECT
    course_code,
    course_name,
    college,
    CASE
        WHEN grade_requirement IS NOT NULL THEN CONCAT(grade_requirement, '%')
        ELSE 'No required grade'
    END as grade_requirement
FROM courses
WHERE is_active = true
AND college != 'GRADUATE SCHOOL'
ORDER BY college, course_name;

-- Query to get graduate programs only
SELECT
    course_code,
    course_name,
    college,
    'Graduate program' as grade_requirement
FROM courses
WHERE is_active = true
AND college = 'GRADUATE SCHOOL'
ORDER BY course_name;

-- Query to search courses by keyword
-- Usage: Replace 'SEARCH_TERM' with your search term
/*
SELECT
    course_code,
    course_name,
    college,
    CASE
        WHEN grade_requirement IS NOT NULL THEN CONCAT(grade_requirement, '%')
        ELSE 'No required grade'
    END as grade_requirement
FROM courses
WHERE is_active = true
AND (LOWER(course_name) LIKE LOWER('%SEARCH_TERM%')
     OR LOWER(college) LIKE LOWER('%SEARCH_TERM%')
     OR LOWER(course_code) LIKE LOWER('%SEARCH_TERM%'))
ORDER BY college, course_name;
*/

-- Query to get course statistics
SELECT
    COUNT(*) as total_courses,
    COUNT(CASE WHEN grade_requirement IS NOT NULL THEN 1 END) as courses_with_grade_req,
    COUNT(CASE WHEN grade_requirement IS NULL THEN 1 END) as courses_without_grade_req,
    AVG(grade_requirement) as average_grade_requirement,
    MIN(grade_requirement) as minimum_grade_requirement,
    MAX(grade_requirement) as maximum_grade_requirement
FROM courses
WHERE is_active = true;

-- Query to get courses by college with grade requirements summary
SELECT
    college,
    COUNT(*) as total_programs,
    COUNT(CASE WHEN grade_requirement IS NOT NULL THEN 1 END) as programs_with_grade_req,
    MIN(grade_requirement) as min_grade_req,
    MAX(grade_requirement) as max_grade_req,
    ROUND(AVG(grade_requirement), 2) as avg_grade_req
FROM courses
WHERE is_active = true
GROUP BY college
ORDER BY college;
