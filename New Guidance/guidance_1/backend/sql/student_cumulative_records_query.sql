-- Student Cumulative Records Query for PLSP Guidance System
-- This query retrieves student cumulative record information with user details

-- Student Cumulative Record Form (SCRF) table
-- This table stores comprehensive student information for the SCRF form

CREATE TABLE IF NOT EXISTS student_cumulative_records (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_id VARCHAR(50) NOT NULL,

    -- Program Information
    program_enrolled VARCHAR(100),
    sex VARCHAR(10),

    -- Personal Information
    full_name VARCHAR(255),
    address TEXT,
    zipcode VARCHAR(20),
    age INTEGER,
    civil_status VARCHAR(50),
    date_of_birth DATE,
    place_of_birth VARCHAR(255),
    lrn VARCHAR(50),
    cellphone VARCHAR(50),
    email_address VARCHAR(255),

    -- Father's Information
    father_name VARCHAR(255),
    father_age INTEGER,
    father_occupation VARCHAR(255),

    -- Mother's Information
    mother_name VARCHAR(255),
    mother_age INTEGER,
    mother_occupation VARCHAR(255),

    -- Guardian Information
    living_with_parents BOOLEAN,
    guardian_name VARCHAR(255),
    guardian_relationship VARCHAR(100),

    -- Brothers/Sisters (stored as JSON array)
    siblings JSONB,

    -- Educational Background (stored as JSON array)
    educational_background JSONB,

    -- Awards Received
    awards_received TEXT,

    -- Transferee Information
    transferee_college_name VARCHAR(255),
    transferee_program VARCHAR(255),

    -- Health Record
    physical_defect TEXT,
    allergies_food TEXT,
    allergies_medicine TEXT,

    -- Admission Officer Use (only accessible by admin/counselor/admission officer)
    exam_taken VARCHAR(255),
    exam_date DATE,
    raw_score DECIMAL(5,2),
    percentile DECIMAL(5,2),
    adjectival_rating VARCHAR(50),

    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by INTEGER REFERENCES users(id),
    updated_by INTEGER REFERENCES users(id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_scrf_user_id ON student_cumulative_records(user_id);
CREATE INDEX IF NOT EXISTS idx_scrf_student_id ON student_cumulative_records(student_id);
CREATE INDEX IF NOT EXISTS idx_scrf_created_at ON student_cumulative_records(created_at);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_scrf_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER trigger_update_scrf_updated_at
    BEFORE UPDATE ON student_cumulative_records
    FOR EACH ROW
    EXECUTE FUNCTION update_scrf_updated_at();

-- Student Cumulative Records Query for PLSP Guidance System
-- This query retrieves student cumulative record information with user details

SELECT
    scrf.id,
    scrf.user_id,
    scrf.student_id,
    scrf.program_enrolled,
    scrf.sex,
    scrf.full_name,
    scrf.address,
    scrf.zipcode,
    scrf.age,
    scrf.civil_status,
    scrf.date_of_birth,
    scrf.place_of_birth,
    scrf.lrn,
    scrf.cellphone,
    scrf.email_address,
    scrf.father_name,
    scrf.father_age,
    scrf.father_occupation,
    scrf.mother_name,
    scrf.mother_age,
    scrf.mother_occupation,
    scrf.living_with_parents,
    scrf.guardian_name,
    scrf.guardian_relationship,
    scrf.siblings,
    scrf.educational_background,
    scrf.awards_received,
    scrf.transferee_college_name,
    scrf.transferee_program,
    scrf.physical_defect,
    scrf.allergies_food,
    scrf.allergies_medicine,
    scrf.exam_taken,
    scrf.exam_date,
    scrf.raw_score,
    scrf.percentile,
    scrf.adjectival_rating,
    scrf.created_at,
    scrf.updated_at,
    scrf.created_by,
    scrf.updated_by,
    u.username as student_username,
    u.first_name as student_first_name,
    u.last_name as student_last_name,
    u.email as student_email,
    u.grade_level,
    u.program,
    u.section,
    cu.username as created_by_username,
    cu.first_name as created_by_first_name,
    cu.last_name as created_by_last_name,
    uu.username as updated_by_username,
    uu.first_name as updated_by_first_name,
    uu.last_name as updated_by_last_name
FROM student_cumulative_records scrf
LEFT JOIN users u ON scrf.user_id = u.id
LEFT JOIN users cu ON scrf.created_by = cu.id
LEFT JOIN users uu ON scrf.updated_by = uu.id
ORDER BY scrf.created_at DESC;
