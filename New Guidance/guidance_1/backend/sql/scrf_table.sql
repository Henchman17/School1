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

-- Insert procedure for SCRF data
CREATE OR REPLACE PROCEDURE insert_scrf_record(
    p_user_id INTEGER,
    p_student_id VARCHAR(50),
    p_program_enrolled VARCHAR(100) DEFAULT NULL,
    p_sex VARCHAR(10) DEFAULT NULL,
    p_full_name VARCHAR(255) DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_zipcode VARCHAR(20) DEFAULT NULL,
    p_age INTEGER DEFAULT NULL,
    p_civil_status VARCHAR(50) DEFAULT NULL,
    p_date_of_birth DATE DEFAULT NULL,
    p_place_of_birth VARCHAR(255) DEFAULT NULL,
    p_lrn VARCHAR(50) DEFAULT NULL,
    p_cellphone VARCHAR(50) DEFAULT NULL,
    p_email_address VARCHAR(255) DEFAULT NULL,
    p_father_name VARCHAR(255) DEFAULT NULL,
    p_father_age INTEGER DEFAULT NULL,
    p_father_occupation VARCHAR(255) DEFAULT NULL,
    p_mother_name VARCHAR(255) DEFAULT NULL,
    p_mother_age INTEGER DEFAULT NULL,
    p_mother_occupation VARCHAR(255) DEFAULT NULL,
    p_living_with_parents BOOLEAN DEFAULT NULL,
    p_guardian_name VARCHAR(255) DEFAULT NULL,
    p_guardian_relationship VARCHAR(100) DEFAULT NULL,
    p_siblings JSONB DEFAULT NULL,
    p_educational_background JSONB DEFAULT NULL,
    p_awards_received TEXT DEFAULT NULL,
    p_transferee_college_name VARCHAR(255) DEFAULT NULL,
    p_transferee_program VARCHAR(255) DEFAULT NULL,
    p_physical_defect TEXT DEFAULT NULL,
    p_allergies_food TEXT DEFAULT NULL,
    p_allergies_medicine TEXT DEFAULT NULL,
    p_exam_taken VARCHAR(255) DEFAULT NULL,
    p_exam_date DATE DEFAULT NULL,
    p_raw_score DECIMAL(5,2) DEFAULT NULL,
    p_percentile DECIMAL(5,2) DEFAULT NULL,
    p_adjectival_rating VARCHAR(50) DEFAULT NULL,
    p_created_by INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO student_cumulative_records (
        user_id, student_id, program_enrolled, sex, full_name, address, zipcode, age,
        civil_status, date_of_birth, place_of_birth, lrn, cellphone, email_address,
        father_name, father_age, father_occupation, mother_name, mother_age, mother_occupation,
        living_with_parents, guardian_name, guardian_relationship, siblings,
        educational_background, awards_received, transferee_college_name, transferee_program,
        physical_defect, allergies_food, allergies_medicine, exam_taken, exam_date,
        raw_score, percentile, adjectival_rating, created_by, updated_by
    ) VALUES (
        p_user_id, p_student_id, p_program_enrolled, p_sex, p_full_name, p_address, p_zipcode, p_age,
        p_civil_status, p_date_of_birth, p_place_of_birth, p_lrn, p_cellphone, p_email_address,
        p_father_name, p_father_age, p_father_occupation, p_mother_name, p_mother_age, p_mother_occupation,
        p_living_with_parents, p_guardian_name, p_guardian_relationship, p_siblings,
        p_educational_background, p_awards_received, p_transferee_college_name, p_transferee_program,
        p_physical_defect, p_allergies_food, p_allergies_medicine, p_exam_taken, p_exam_date,
        p_raw_score, p_percentile, p_adjectival_rating, p_created_by, p_created_by
    );

    RAISE NOTICE 'SCRF record inserted successfully for user ID: %', p_user_id;
END;
$$;

-- Update procedure for SCRF data
CREATE OR REPLACE PROCEDURE update_scrf_record(
    p_user_id INTEGER,
    p_program_enrolled VARCHAR(100) DEFAULT NULL,
    p_sex VARCHAR(10) DEFAULT NULL,
    p_full_name VARCHAR(255) DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_zipcode VARCHAR(20) DEFAULT NULL,
    p_age INTEGER DEFAULT NULL,
    p_civil_status VARCHAR(50) DEFAULT NULL,
    p_date_of_birth DATE DEFAULT NULL,
    p_place_of_birth VARCHAR(255) DEFAULT NULL,
    p_lrn VARCHAR(50) DEFAULT NULL,
    p_cellphone VARCHAR(50) DEFAULT NULL,
    p_email_address VARCHAR(255) DEFAULT NULL,
    p_father_name VARCHAR(255) DEFAULT NULL,
    p_father_age INTEGER DEFAULT NULL,
    p_father_occupation VARCHAR(255) DEFAULT NULL,
    p_mother_name VARCHAR(255) DEFAULT NULL,
    p_mother_age INTEGER DEFAULT NULL,
    p_mother_occupation VARCHAR(255) DEFAULT NULL,
    p_living_with_parents BOOLEAN DEFAULT NULL,
    p_guardian_name VARCHAR(255) DEFAULT NULL,
    p_guardian_relationship VARCHAR(100) DEFAULT NULL,
    p_siblings JSONB DEFAULT NULL,
    p_educational_background JSONB DEFAULT NULL,
    p_awards_received TEXT DEFAULT NULL,
    p_transferee_college_name VARCHAR(255) DEFAULT NULL,
    p_transferee_program VARCHAR(255) DEFAULT NULL,
    p_physical_defect TEXT DEFAULT NULL,
    p_allergies_food TEXT DEFAULT NULL,
    p_allergies_medicine TEXT DEFAULT NULL,
    p_exam_taken VARCHAR(255) DEFAULT NULL,
    p_exam_date DATE DEFAULT NULL,
    p_raw_score DECIMAL(5,2) DEFAULT NULL,
    p_percentile DECIMAL(5,2) DEFAULT NULL,
    p_adjectival_rating VARCHAR(50) DEFAULT NULL,
    p_updated_by INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE student_cumulative_records
    SET
        program_enrolled = COALESCE(p_program_enrolled, program_enrolled),
        sex = COALESCE(p_sex, sex),
        full_name = COALESCE(p_full_name, full_name),
        address = COALESCE(p_address, address),
        zipcode = COALESCE(p_zipcode, zipcode),
        age = COALESCE(p_age, age),
        civil_status = COALESCE(p_civil_status, civil_status),
        date_of_birth = COALESCE(p_date_of_birth, date_of_birth),
        place_of_birth = COALESCE(p_place_of_birth, place_of_birth),
        lrn = COALESCE(p_lrn, lrn),
        cellphone = COALESCE(p_cellphone, cellphone),
        email_address = COALESCE(p_email_address, email_address),
        father_name = COALESCE(p_father_name, father_name),
        father_age = COALESCE(p_father_age, father_age),
        father_occupation = COALESCE(p_father_occupation, father_occupation),
        mother_name = COALESCE(p_mother_name, mother_name),
        mother_age = COALESCE(p_mother_age, mother_age),
        mother_occupation = COALESCE(p_mother_occupation, mother_occupation),
        living_with_parents = COALESCE(p_living_with_parents, living_with_parents),
        guardian_name = COALESCE(p_guardian_name, guardian_name),
        guardian_relationship = COALESCE(p_guardian_relationship, guardian_relationship),
        siblings = COALESCE(p_siblings, siblings),
        educational_background = COALESCE(p_educational_background, educational_background),
        awards_received = COALESCE(p_awards_received, awards_received),
        transferee_college_name = COALESCE(p_transferee_college_name, transferee_college_name),
        transferee_program = COALESCE(p_transferee_program, transferee_program),
        physical_defect = COALESCE(p_physical_defect, physical_defect),
        allergies_food = COALESCE(p_allergies_food, allergies_food),
        allergies_medicine = COALESCE(p_allergies_medicine, allergies_medicine),
        exam_taken = COALESCE(p_exam_taken, exam_taken),
        exam_date = COALESCE(p_exam_date, exam_date),
        raw_score = COALESCE(p_raw_score, raw_score),
        percentile = COALESCE(p_percentile, percentile),
        adjectival_rating = COALESCE(p_adjectival_rating, adjectival_rating),
        updated_by = COALESCE(p_updated_by, updated_by)
    WHERE user_id = p_user_id;

    IF FOUND THEN
        RAISE NOTICE 'SCRF record updated successfully for user ID: %', p_user_id;
    ELSE
        RAISE EXCEPTION 'No SCRF record found for user ID: %', p_user_id;
    END IF;
END;
$$;

-- Function to get SCRF record with user and student details
CREATE OR REPLACE FUNCTION get_scrf_record(p_user_id INTEGER)
RETURNS TABLE(
    scrf_id INTEGER,
    user_id INTEGER,
    student_id VARCHAR(50),
    username VARCHAR(100),
    student_number VARCHAR(50),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    program_enrolled VARCHAR(100),
    sex VARCHAR(10),
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
    father_name VARCHAR(255),
    father_age INTEGER,
    father_occupation VARCHAR(255),
    mother_name VARCHAR(255),
    mother_age INTEGER,
    mother_occupation VARCHAR(255),
    living_with_parents BOOLEAN,
    guardian_name VARCHAR(255),
    guardian_relationship VARCHAR(100),
    siblings JSONB,
    educational_background JSONB,
    awards_received TEXT,
    transferee_college_name VARCHAR(255),
    transferee_program VARCHAR(255),
    physical_defect TEXT,
    allergies_food TEXT,
    allergies_medicine TEXT,
    exam_taken VARCHAR(255),
    exam_date DATE,
    raw_score DECIMAL(5,2),
    percentile DECIMAL(5,2),
    adjectival_rating VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        scrf.id,
        scrf.user_id,
        scrf.student_id,
        u.username,
        u.student_id,
        u.first_name,
        u.last_name,
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
        scrf.updated_at
    FROM student_cumulative_records scrf
    JOIN users u ON scrf.user_id = u.id
    WHERE scrf.user_id = p_user_id;
END;
$$;

-- Function to get all SCRF records (for admin/counselor)
CREATE OR REPLACE FUNCTION get_all_scrf_records()
RETURNS TABLE(
    scrf_id INTEGER,
    user_id INTEGER,
    student_id VARCHAR(50),
    username VARCHAR(100),
    student_number VARCHAR(50),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    program_enrolled VARCHAR(100),
    sex VARCHAR(10),
    full_name VARCHAR(255),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        scrf.id,
        scrf.user_id,
        scrf.student_id,
        u.username,
        u.student_id,
        u.first_name,
        u.last_name,
        scrf.program_enrolled,
        scrf.sex,
        scrf.full_name,
        scrf.created_at,
        scrf.updated_at
    FROM student_cumulative_records scrf
    JOIN users u ON scrf.user_id = u.id
    ORDER BY scrf.created_at DESC;
END;
$$;

-- Sample usage examples
/*
-- Insert a new SCRF record
CALL insert_scrf_record(
    1, 1, 'Bachelor of Science in Information Technology', 'Male',
    'Juan Dela Cruz', '123 Main St, Manila', '1000', 18, 'Single',
    '2006-01-15', 'Manila', '123456789012', '09123456789', 'juan.delacruz@email.com',
    'Pedro Dela Cruz', 45, 'Engineer', 'Maria Dela Cruz', 42, 'Teacher',
    true, null, null,
    '[{"name": "Anna Dela Cruz", "civil_status": "Single", "occupation": "Student"}]',
    '[{"grade": "7", "school": "Elementary School", "year_completed": "2019"}, {"grade": "8", "school": "Elementary School", "year_completed": "2020"}]',
    'Academic Excellence Award 2023',
    null, null,
    'None', 'Peanuts', 'Aspirin',
    'Entrance Exam', '2024-06-15', 85.5, 90.0, 'Superior',
    2
);

-- Update an existing SCRF record
CALL update_scrf_record(
    1, 'Bachelor of Science in Computer Science', 'Male',
    'Juan Pedro Dela Cruz', '456 Oak St, Quezon City', '1100', 19, 'Single',
    '2005-03-20', 'Quezon City', '123456789013', '09123456790', 'juan.pedro@email.com',
    'Pedro Dela Cruz', 46, 'Senior Engineer', 'Maria Dela Cruz', 43, 'Principal',
    true, null, null,
    '[{"name": "Anna Dela Cruz", "civil_status": "Single", "occupation": "College Student"}, {"name": "Miguel Dela Cruz", "civil_status": "Single", "occupation": "Student"}]',
    '[{"grade": "7", "school": "St. Mary Elementary", "year_completed": "2019"}, {"grade": "8", "school": "St. Mary Elementary", "year_completed": "2020"}, {"grade": "9", "school": "St. Joseph High School", "year_completed": "2021"}]',
    'Academic Excellence Award 2023, Science Fair Winner 2022',
    null, null,
    'None', 'Peanuts, Shellfish', 'Aspirin, Penicillin',
    'College Entrance Exam', '2024-08-20', 88.0, 92.5, 'Superior',
    2
);

-- Get SCRF record for a specific user
SELECT * FROM get_scrf_record(1);

-- Get all SCRF records (admin view)
SELECT * FROM get_all_scrf_records();
*/
