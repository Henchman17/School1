-- Create courses table with sample data
CREATE TABLE IF NOT EXISTS courses (
    id SERIAL PRIMARY KEY,
    course_code VARCHAR(20) UNIQUE NOT NULL,
    course_name VARCHAR(255) NOT NULL,
    college VARCHAR(100) NOT NULL,
    grade_requirement DECIMAL(5,2),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Insert sample courses
INSERT INTO courses (course_code, course_name, college, grade_requirement, description) VALUES
-- COLLEGE OF TEACHER EDUCATION
('BEED', 'Bachelor in Elementary Education', 'COLLEGE OF TEACHER EDUCATION', 85.00, 'Grade requirements not lower than 85%'),
('BSED-ENG', 'Bachelor in Secondary Education Major in English', 'COLLEGE OF TEACHER EDUCATION', 85.00, 'Grade requirements not lower than 85%'),
('BSED-FIL', 'Bachelor in Secondary Education Major in Filipino', 'COLLEGE OF TEACHER EDUCATION', 85.00, 'Grade requirements not lower than 85%'),
('BSED-SCI', 'Bachelor in Secondary Education Major in Science', 'COLLEGE OF TEACHER EDUCATION', 85.00, 'Grade requirements not lower than 85%'),
('BSED-SS', 'Bachelor in Secondary Education Major in Social Studies', 'COLLEGE OF TEACHER EDUCATION', 85.00, 'Grade requirements not lower than 85%'),
('BSED-MATH', 'Bachelor of Secondary Education Major in Math', 'COLLEGE OF TEACHER EDUCATION', 85.00, 'Grade requirements not lower than 85%'),

-- COLLEGE OF BUSINESS AND HOSPITALITY MANAGEMENT
('BSHM', 'Bachelor of Science in Hospitality Management', 'COLLEGE OF BUSINESS AND HOSPITALITY MANAGEMENT', 83.00, 'Grade requirements not lower than 83%'),
('BSBA-FM', 'Bachelor of Science in Business Administration Major in Financial Management', 'COLLEGE OF BUSINESS AND HOSPITALITY MANAGEMENT', 83.00, 'Grade requirements not lower than 83%'),
('BSBA-MM', 'Bachelor of Science in Business Administration Major in Marketing Management', 'COLLEGE OF BUSINESS AND HOSPITALITY MANAGEMENT', 83.00, 'Grade requirements not lower than 83%'),
('BSBA-HRDM', 'Bachelor of Science in Business Administration Major in Human Resource Development Management', 'COLLEGE OF BUSINESS AND HOSPITALITY MANAGEMENT', 83.00, 'Grade requirements not lower than 83%'),
('BSOA', 'Bachelor of Science in Office Administration', 'COLLEGE OF BUSINESS AND HOSPITALITY MANAGEMENT', 80.00, 'Grade requirements not lower than 80%'),

-- COLLEGE OF ARTS AND SCIENCES
('BSPSYCH', 'Bachelor of Science in Psychology', 'COLLEGE OF ARTS AND SCIENCES', 83.00, 'Grade requirements not lower than 83%'),
('BSPAD', 'Bachelor of Science in Public Administration', 'COLLEGE OF ARTS AND SCIENCES', NULL, 'No required grade'),
('AB-POLSCI', 'Bachelor of Arts in Political Science', 'COLLEGE OF ARTS AND SCIENCES', NULL, 'No required grade'),

-- COLLEGE OF ACCOUNTANCY AND ENTREPRENEURSHIP
('BSA', 'Bachelor of Science in Accountancy', 'COLLEGE OF ACCOUNTANCY AND ENTREPRENEURSHIP', 88.00, 'Grade requirements not lower than 88%'),
('BSAIS', 'Bachelor of Science in Accounting Information System', 'COLLEGE OF ACCOUNTANCY AND ENTREPRENEURSHIP', 85.00, 'Grade requirements not lower than 85%'),
('BSMA', 'Bachelor of Science in Management Accounting', 'COLLEGE OF ACCOUNTANCY AND ENTREPRENEURSHIP', 85.00, 'Grade requirements not lower than 85%'),
('BSENTREP', 'Bachelor of Science in Entrepreneurship', 'COLLEGE OF ACCOUNTANCY AND ENTREPRENEURSHIP', NULL, 'No required grade'),

-- COLLEGE OF COMPUTER STUDIES AND TECHNOLOGY
('BSIT', 'Bachelor of Science in Information Technology', 'COLLEGE OF COMPUTER STUDIES AND TECHNOLOGY', 83.00, 'Grade requirements not lower than 83%'),
('BSIS', 'Bachelor of Science in Information System', 'COLLEGE OF COMPUTER STUDIES AND TECHNOLOGY', 83.00, 'Grade requirements not lower than 83%'),

-- COLLEGE OF ENGINEERING
('BSCOE', 'Bachelor of Science in Computer Engineering', 'COLLEGE OF ENGINEERING', 83.00, 'Grade requirements not lower than 83%'),

-- GRADUATE SCHOOL
('MAED-EM', 'Master of Arts in Education Major in Educational Management', 'GRADUATE SCHOOL', NULL, 'Graduate program'),
('MAED-ENG', 'Master of Arts in Education Major in English Language Education', 'GRADUATE SCHOOL', NULL, 'Graduate program'),
('MAED-STE', 'Master of Arts in Education Major in Science and Technology Education', 'GRADUATE SCHOOL', NULL, 'Graduate program'),
('MAED-MATH', 'Master of Arts in Education Major in Mathematics Education', 'GRADUATE SCHOOL', NULL, 'Graduate program'),
('MAED-SS', 'Master of Arts in Education Major in Social Studies Education', 'GRADUATE SCHOOL', NULL, 'Graduate program'),
('MAED-FIL', 'Master of Arts in Education Major in Filipino Education', 'GRADUATE SCHOOL', NULL, 'Graduate program'),
('MPA', 'Master in Public Administration', 'GRADUATE SCHOOL', NULL, 'Graduate program'),
('MBA', 'Master in Business Administration', 'GRADUATE SCHOOL', NULL, 'Graduate program')
ON CONFLICT (course_code) DO NOTHING;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_courses_college ON courses(college);
CREATE INDEX IF NOT EXISTS idx_courses_is_active ON courses(is_active);
