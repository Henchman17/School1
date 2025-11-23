-- Examples of using the user signup procedures and JOIN queries
-- Run these examples to see how the JOIN operations work

-- =====================================================
-- EXAMPLE 1: Create a new student user
-- =====================================================

-- Create a student user using the stored procedure
CALL create_student_user(
    'alexsmith',           -- username
    'alex.smith@plsp.edu.ph', -- email
    'hashed_password_123', -- password (should be hashed in production)
    'Alex',                -- first_name
    'Smith',               -- last_name
    '12',                  -- grade_level
    'STEM-B'               -- section
);

-- =====================================================
-- EXAMPLE 2: Retrieve user with student details
-- =====================================================

-- Get details for a specific user (replace 1 with actual user ID)
SELECT * FROM get_user_student_details(1);

-- =====================================================
-- EXAMPLE 3: View all students with user details
-- =====================================================

-- See all students joined with their user information
SELECT * FROM student_user_details;

-- =====================================================
-- EXAMPLE 4: Search students
-- =====================================================

-- Search by name
SELECT * FROM search_students('alex');

-- Search by email
SELECT * FROM search_students('smith');

-- =====================================================
-- EXAMPLE 5: Manual verification of JOIN
-- =====================================================

-- Verify the relationship between users and students
SELECT
    u.id as user_id,
    u.username,
    u.email,
    u.role,
    s.student_id,
    s.first_name,
    s.last_name,
    s.grade_level,
    s.section
FROM users u
JOIN students s ON u.id = s.user_id
WHERE u.role = 'student'
ORDER BY s.last_name, s.first_name;

-- =====================================================
-- EXAMPLE 6: Count users by role
-- =====================================================

-- See how many users of each role exist
SELECT
    u.role,
    COUNT(*) as user_count,
    COUNT(s.id) as student_records
FROM users u
LEFT JOIN students s ON u.id = s.user_id
GROUP BY u.role
ORDER BY u.role;

-- =====================================================
-- EXAMPLE 7: Recent signups with JOIN
-- =====================================================

-- Get recently created users with their student details
SELECT
    u.username,
    u.email,
    u.created_at as signup_date,
    s.student_id,
    s.first_name,
    s.last_name,
    s.grade_level,
    s.section
FROM users u
LEFT JOIN students s ON u.id = s.user_id
WHERE u.created_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY u.created_at DESC;

-- =====================================================
-- CLEANUP EXAMPLES (Use with caution!)
-- =====================================================

-- Delete a test user (this will cascade to students table)
-- DELETE FROM users WHERE username = 'alexsmith';

-- Check remaining data
-- SELECT COUNT(*) as users_count FROM users;
-- SELECT COUNT(*) as students_count FROM students;
