-- Alter Re-admission Cases Table to match the expected schema
-- This script modifies the existing re_admission_cases table to add missing columns and remove old ones

-- Remove old columns that are no longer needed
DO $$
BEGIN
    -- Drop old columns if they exist
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 're_admission_cases'
               AND column_name = 'gpa') THEN
        ALTER TABLE re_admission_cases DROP COLUMN gpa;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 're_admission_cases'
               AND column_name = 'academic_standing') THEN
        ALTER TABLE re_admission_cases DROP COLUMN academic_standing;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 're_admission_cases'
               AND column_name = 'reason_for_return') THEN
        ALTER TABLE re_admission_cases DROP COLUMN reason_for_return;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 're_admission_cases'
               AND column_name = 'reason_for_leaving') THEN
        ALTER TABLE re_admission_cases DROP COLUMN reason_for_leaving;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 're_admission_cases'
               AND column_name = 'admin_notes') THEN
        ALTER TABLE re_admission_cases DROP COLUMN admin_notes;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 're_admission_cases'
               AND column_name = 'previous_program') THEN
        ALTER TABLE re_admission_cases DROP COLUMN previous_program;
    END IF;
END $$;

-- Add reason_of_absence column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 're_admission_cases'
                   AND column_name = 'reason_of_absence') THEN
        ALTER TABLE re_admission_cases ADD COLUMN reason_of_absence TEXT;
    END IF;
END $$;

-- Add notes column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 're_admission_cases'
                   AND column_name = 'notes') THEN
        ALTER TABLE re_admission_cases ADD COLUMN notes TEXT;
    END IF;
END $$;

-- Add status column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 're_admission_cases'
                   AND column_name = 'status') THEN
        ALTER TABLE re_admission_cases ADD COLUMN status VARCHAR(50) NOT NULL DEFAULT 'pending';
    END IF;
END $$;

-- Add counselor_id column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 're_admission_cases'
                   AND column_name = 'counselor_id') THEN
        ALTER TABLE re_admission_cases ADD COLUMN counselor_id INTEGER REFERENCES users(id);
    END IF;
END $$;

-- Add created_at column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 're_admission_cases'
                   AND column_name = 'created_at') THEN
        ALTER TABLE re_admission_cases ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT NOW();
    END IF;
END $$;

-- Add updated_at column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 're_admission_cases'
                   AND column_name = 'updated_at') THEN
        ALTER TABLE re_admission_cases ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT NOW();
    END IF;
END $$;

-- Add reviewed_at column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 're_admission_cases'
                   AND column_name = 'reviewed_at') THEN
        ALTER TABLE re_admission_cases ADD COLUMN reviewed_at TIMESTAMP;
    END IF;
END $$;

-- Add reviewed_by column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 're_admission_cases'
                   AND column_name = 'reviewed_by') THEN
        ALTER TABLE re_admission_cases ADD COLUMN reviewed_by INTEGER REFERENCES users(id);
    END IF;
END $$;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_re_admission_cases_status ON re_admission_cases(status);
CREATE INDEX IF NOT EXISTS idx_re_admission_cases_created_at ON re_admission_cases(created_at);
CREATE INDEX IF NOT EXISTS idx_re_admission_cases_counselor_id ON re_admission_cases(counselor_id);
