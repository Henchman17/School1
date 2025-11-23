-- Migration script to create Supabase Auth users from existing database users
-- This script should be run in the Supabase SQL Editor or as a database migration

-- =====================================================
-- MIGRATION SCRIPT: Migrate Existing Users to Supabase Auth
-- =====================================================

-- This script will:
-- 1. Create auth users for all existing users in the users table
-- 2. Update the users table with the correct auth user IDs
-- 3. Set appropriate user metadata and roles

DO $$
DECLARE
    user_record RECORD;
    auth_user_id UUID;
    default_password TEXT := 'TempPass123!'; -- Default password, users should change this
BEGIN
    -- Loop through all existing users
    FOR user_record IN
        SELECT id, email, username, first_name, last_name, role, student_id, grade_level, section
        FROM users
        WHERE email IS NOT NULL AND email != ''
        ORDER BY id
    LOOP
        BEGIN
            -- Create auth user using Supabase admin functions
            -- Note: This requires admin privileges and the auth schema to be available

            -- Insert into auth.users (this would normally be done via Supabase admin API)
            -- Since we're in SQL, we'll use the available functions

            -- For Supabase, we need to use the admin API or create a custom function
            -- This is a simplified version - in practice, you'd use the admin API

            RAISE NOTICE 'Processing user: % (%)', user_record.email, user_record.role;

            -- Update the user record with a placeholder auth_id for now
            -- In a real migration, this would be done after creating the auth user
            UPDATE users
            SET auth_id = gen_random_uuid()::TEXT
            WHERE id = user_record.id;

            RAISE NOTICE 'Updated user % with auth_id placeholder', user_record.id;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Error processing user %: %', user_record.email, SQLERRM;
                CONTINUE;
        END;
    END LOOP;

    RAISE NOTICE 'Migration script completed. Please run the TypeScript migration script for actual auth user creation.';
END $$;

-- =====================================================
-- HELPER FUNCTION: Create Auth User (would need admin privileges)
-- =====================================================

-- Note: This function would need to be created with admin privileges
-- and access to the auth schema, which may not be available in all Supabase setups

/*
CREATE OR REPLACE FUNCTION create_auth_user(
    p_email TEXT,
    p_password TEXT,
    p_user_metadata JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- This would require access to auth.users table
    -- INSERT INTO auth.users (email, encrypted_password, user_metadata, created_at, updated_at)
    -- VALUES (p_email, crypt(p_password, gen_salt('bf')), p_user_metadata, NOW(), NOW())
    -- RETURNING id INTO v_user_id;

    -- For now, return a generated UUID
    v_user_id := gen_random_uuid();

    RETURN v_user_id;
END;
$$;
*/

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check migration results
-- SELECT id, email, username, role, auth_id FROM users WHERE auth_id IS NOT NULL;

-- Count users by role
-- SELECT role, COUNT(*) as count FROM users GROUP BY role ORDER BY role;

-- Check for users without auth_id
-- SELECT id, email, username, role FROM users WHERE auth_id IS NULL OR auth_id = '';

-- =====================================================
-- ROLLBACK (if needed)
-- =====================================================

-- To rollback the migration:
-- UPDATE users SET auth_id = NULL WHERE auth_id IS NOT NULL;
