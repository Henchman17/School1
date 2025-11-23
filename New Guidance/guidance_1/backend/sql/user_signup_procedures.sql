-- SQL procedures and queries for user signup
-- This file contains stored procedures and queries for handling user registration
-- All student data is stored in the users table

-- =====================================================
-- STORED PROCEDURE: Create Student User
-- =====================================================
-- This procedure creates a student user in the users table
CREATE OR REPLACE PROCEDURE create_student_user(
    p_username VARCHAR(100),
    p_email VARCHAR(255),
    p_password VARCHAR(255),
    p_first_name VARCHAR(100),
    p_last_name VARCHAR(100),
    p_grade_level VARCHAR(20) DEFAULT '1st',
    p_section VARCHAR(50) DEFAULT 'Unknown'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id INTEGER;
    v_student_id VARCHAR(50);
BEGIN
    -- Start transaction
    BEGIN
        -- Generate student ID
        -- Get the next user ID to generate student ID
        SELECT COALESCE(MAX(id), 0) + 1 INTO v_user_id FROM users;

        v_student_id := 'STU' || LPAD(v_user_id::TEXT, 4, '0');

        -- Insert into users table with all student information
        INSERT INTO users (username, email, password, role, student_id, first_name, last_name, grade_level, section)
        VALUES (p_username, p_email, p_password, 'student', v_student_id, p_first_name, p_last_name, p_grade_level, p_section)
        RETURNING id INTO v_user_id;

        -- Commit transaction (automatic in PostgreSQL stored procedures)
        RAISE NOTICE 'Student user created successfully. User ID: %, Student ID: %', v_user_id, v_student_id;

    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback will happen automatically
            RAISE EXCEPTION 'Failed to create student user: %', SQLERRM;
    END;
END;
$$;

-- =====================================================
-- FUNCTION: Get User with Student Details
-- =====================================================
-- This function returns user information (all student data is in users table)

-- Drop the existing function first if it exists with different signature
DROP FUNCTION IF EXISTS get_user_student_details(INTEGER);

CREATE FUNCTION get_user_student_details(p_user_id INTEGER)
RETURNS TABLE(
    user_id INTEGER,
    username VARCHAR(100),
    email VARCHAR(255),
    role VARCHAR(50),
    user_created_at TIMESTAMP,
    student_id VARCHAR(50),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    grade_level VARCHAR(20),
    section VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id,
        u.username,
        u.email,
        u.role,
        u.created_at,
        u.student_id,
        u.first_name,
        u.last_name,
        u.grade_level,
        u.section
    FROM users u
    WHERE u.id = p_user_id;
END;
$$;

-- =====================================================
-- QUERY: Get All Students with User Details
-- =====================================================
-- This query gets all student information from the users table
CREATE OR REPLACE VIEW student_user_details AS
SELECT
    u.id as user_id,
    u.username,
    u.email,
    u.role,
    u.created_at as user_created_at,
    u.student_id,
    u.first_name,
    u.last_name,
    u.grade_level,
    u.section
FROM users u
WHERE u.role = 'student'
ORDER BY u.last_name, u.first_name;

-- =====================================================
-- QUERY: Search Students by Name or Email
-- =====================================================
CREATE OR REPLACE FUNCTION search_students(search_term TEXT)
RETURNS TABLE(
    user_id INTEGER,
    username VARCHAR(100),
    email VARCHAR(255),
    student_id VARCHAR(50),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    grade_level VARCHAR(20),
    section VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id,
        u.username,
        u.email,
        u.student_id,
        u.first_name,
        u.last_name,
        u.grade_level,
        u.section
    FROM users u
    WHERE u.role = 'student'
    AND (
        LOWER(u.first_name) LIKE LOWER('%' || search_term || '%')
        OR LOWER(u.last_name) LIKE LOWER('%' || search_term || '%')
        OR LOWER(u.email) LIKE LOWER('%' || search_term || '%')
        OR LOWER(u.username) LIKE LOWER('%' || search_term || '%')
    )
    ORDER BY u.last_name, u.first_name;
END;
$$;

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================

-- Example 1: Create a new student user using the stored procedure
-- CALL create_student_user('johndoe', 'john.doe@plsp.edu.ph', 'hashed_password', 'John', 'Doe', '1st', 'STEM-A');

-- Example 2: Get user details with student information
-- SELECT * FROM get_user_student_details(1);

-- Example 3: Get all students with user details
-- SELECT * FROM student_user_details;

-- Example 4: Search students
-- SELECT * FROM search_students('john');

-- Example 5: Manual INSERT (all student data is in users table)
-- Note: All student information is stored directly in the users table
/*
-- Insert student user (all data in one table)
INSERT INTO users (username, email, password, role, student_id, first_name, last_name, grade_level, section)
VALUES ('janedoe', 'jane.doe@plsp.edu.ph', 'hashed_password', 'student', 'STU0005', 'Jane', 'Doe', '2nd', 'ABM-B');

-- Verify the student data
SELECT username, email, student_id, first_name, last_name, grade_level, section
FROM users
WHERE username = 'janedoe';
*/

-- =====================================================
-- CLEANUP QUERIES (for testing)
-- =====================================================

-- Delete a student user
-- DELETE FROM users WHERE id = 1;

-- Get count of users by role
-- SELECT role, COUNT(*) as count FROM users GROUP BY role ORDER BY role;
