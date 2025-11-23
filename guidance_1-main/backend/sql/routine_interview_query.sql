-- SQL query to retrieve routine interview data for a student by user ID
SELECT
  ri.id,
  ri.name,
  ri.date,
  ri.grade_course_year_section,
  ri.nickname,
  ri.ordinal_position,
  ri.student_description,
  ri.familial_description,
  ri.strengths,
  ri.weaknesses,
  ri.achievements,
  ri.best_work_person,
  ri.first_choice,
  ri.goals,
  ri.contribution,
  ri.talents_skills,
  ri.home_problems,
  ri.school_problems,
  ri.applicant_signature,
  ri.signature_date,
  s.student_id,
  s.first_name,
  s.last_name,
  s.grade_level,
  s.section
FROM routine_interviews ri
JOIN students s ON ri.student_id = s.id
JOIN users u ON s.user_id = u.id
WHERE u.id = $1; -- Replace $1 with the user ID parameter
