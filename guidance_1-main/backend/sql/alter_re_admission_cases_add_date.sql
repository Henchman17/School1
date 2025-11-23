-- Add date column to re_admission_cases table

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 're_admission_cases'
                   AND column_name = 'date') THEN
        ALTER TABLE re_admission_cases ADD COLUMN date DATE;
    END IF;
END $$;
