-- Create routine_interviews table for storing routine interview form data
CREATE TABLE IF NOT EXISTS routine_interviews (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    grade_course_year_section VARCHAR(100),
    nickname VARCHAR(100),
    ordinal_position VARCHAR(50),
    student_description TEXT,
    familial_description TEXT,
    strengths TEXT,
    weaknesses TEXT,
    achievements TEXT,
    best_work_person TEXT,
    first_choice TEXT,
    goals TEXT,
    contribution TEXT,
    talents_skills TEXT,
    home_problems TEXT,
    school_problems TEXT,
    applicant_signature VARCHAR(255),
    signature_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_routine_interviews_student_id ON routine_interviews(student_id);
CREATE INDEX IF NOT EXISTS idx_routine_interviews_date ON routine_interviews(date);
CREATE INDEX IF NOT EXISTS idx_routine_interviews_created_at ON routine_interviews(created_at);

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
  ri.created_at,
  ri.updated_at,
  u.username as student_username,
  u.first_name as student_first_name,
  u.last_name as student_last_name,
  u.email as student_email,
  u.grade_level,
  u.program,
  u.section
FROM routine_interviews ri
JOIN users u ON ri.student_id = u.id
WHERE u.id = $1; -- Replace $1 with the user ID parameter
