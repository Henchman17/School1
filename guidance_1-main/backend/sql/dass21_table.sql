-- Psych Exam (DASS-21) table
-- This table stores DASS-21 assessment responses for mental health screening

CREATE TABLE IF NOT EXISTS psych_exam (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    student_id VARCHAR(50) NOT NULL,

    -- Personal Information
    full_name VARCHAR(255),
    program VARCHAR(100),
    major VARCHAR(100),

    -- Assessment Date
    assessment_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- DASS-21 Questions (0-3 scale responses)
    q1_hard_to_wind_down INTEGER CHECK (q1_hard_to_wind_down >= 0 AND q1_hard_to_wind_down <= 3),
    q2_dry_mouth INTEGER CHECK (q2_dry_mouth >= 0 AND q2_dry_mouth <= 3),
    q3_no_positive_feeling INTEGER CHECK (q3_no_positive_feeling >= 0 AND q3_no_positive_feeling <= 3),
    q4_breathing_difficulty INTEGER CHECK (q4_breathing_difficulty >= 0 AND q4_breathing_difficulty <= 3),
    q5_difficult_initiative INTEGER CHECK (q5_difficult_initiative >= 0 AND q5_difficult_initiative <= 3),
    q6_over_react INTEGER CHECK (q6_over_react >= 0 AND q6_over_react <= 3),
    q7_trembling INTEGER CHECK (q7_trembling >= 0 AND q7_trembling <= 3),
    q8_nervous_energy INTEGER CHECK (q8_nervous_energy >= 0 AND q8_nervous_energy <= 3),
    q9_worried_panic INTEGER CHECK (q9_worried_panic >= 0 AND q9_worried_panic <= 3),
    q10_nothing_to_look_forward INTEGER CHECK (q10_nothing_to_look_forward >= 0 AND q10_nothing_to_look_forward <= 3),
    q11_getting_agitated INTEGER CHECK (q11_getting_agitated >= 0 AND q11_getting_agitated <= 3),
    q12_difficult_relax INTEGER CHECK (q12_difficult_relax >= 0 AND q12_difficult_relax <= 3),
    q13_down_hearted INTEGER CHECK (q13_down_hearted >= 0 AND q13_down_hearted <= 3),
    q14_intolerant_delays INTEGER CHECK (q14_intolerant_delays >= 0 AND q14_intolerant_delays <= 3),
    q15_close_to_panic INTEGER CHECK (q15_close_to_panic >= 0 AND q15_close_to_panic <= 3),
    q16_unable_enthusiastic INTEGER CHECK (q16_unable_enthusiastic >= 0 AND q16_unable_enthusiastic <= 3),
    q17_not_worth_much INTEGER CHECK (q17_not_worth_much >= 0 AND q17_not_worth_much <= 3),
    q18_rather_touchy INTEGER CHECK (q18_rather_touchy >= 0 AND q18_rather_touchy <= 3),
    q19_heart_action INTEGER CHECK (q19_heart_action >= 0 AND q19_heart_action <= 3),
    q20_scared_no_reason INTEGER CHECK (q20_scared_no_reason >= 0 AND q20_scared_no_reason <= 3),
    q21_life_meaningless INTEGER CHECK (q21_life_meaningless >= 0 AND q21_life_meaningless <= 3),

    -- Calculated Scores
    depression_score INTEGER GENERATED ALWAYS AS (
        q3_no_positive_feeling + q5_difficult_initiative + q10_nothing_to_look_forward +
        q13_down_hearted + q16_unable_enthusiastic + q17_not_worth_much + q21_life_meaningless
    ) STORED,

    anxiety_score INTEGER GENERATED ALWAYS AS (
        q2_dry_mouth + q4_breathing_difficulty + q7_trembling + q9_worried_panic +
        q15_close_to_panic + q19_heart_action + q20_scared_no_reason
    ) STORED,

    stress_score INTEGER GENERATED ALWAYS AS (
        q1_hard_to_wind_down + q6_over_react + q8_nervous_energy + q11_getting_agitated +
        q12_difficult_relax + q14_intolerant_delays + q18_rather_touchy
    ) STORED,

    -- Severity Levels (calculated based on scores)
    depression_severity VARCHAR(20) GENERATED ALWAYS AS (
        CASE
            WHEN (q3_no_positive_feeling + q5_difficult_initiative + q10_nothing_to_look_forward +
                  q13_down_hearted + q16_unable_enthusiastic + q17_not_worth_much + q21_life_meaningless) <= 4 THEN 'Normal'
            WHEN (q3_no_positive_feeling + q5_difficult_initiative + q10_nothing_to_look_forward +
                  q13_down_hearted + q16_unable_enthusiastic + q17_not_worth_much + q21_life_meaningless) <= 6 THEN 'Mild'
            WHEN (q3_no_positive_feeling + q5_difficult_initiative + q10_nothing_to_look_forward +
                  q13_down_hearted + q16_unable_enthusiastic + q17_not_worth_much + q21_life_meaningless) <= 10 THEN 'Moderate'
            WHEN (q3_no_positive_feeling + q5_difficult_initiative + q10_nothing_to_look_forward +
                  q13_down_hearted + q16_unable_enthusiastic + q17_not_worth_much + q21_life_meaningless) <= 13 THEN 'Severe'
            ELSE 'Extremely Severe'
        END
    ) STORED,

    anxiety_severity VARCHAR(20) GENERATED ALWAYS AS (
        CASE
            WHEN (q2_dry_mouth + q4_breathing_difficulty + q7_trembling + q9_worried_panic +
                  q15_close_to_panic + q19_heart_action + q20_scared_no_reason) <= 3 THEN 'Normal'
            WHEN (q2_dry_mouth + q4_breathing_difficulty + q7_trembling + q9_worried_panic +
                  q15_close_to_panic + q19_heart_action + q20_scared_no_reason) <= 5 THEN 'Mild'
            WHEN (q2_dry_mouth + q4_breathing_difficulty + q7_trembling + q9_worried_panic +
                  q15_close_to_panic + q19_heart_action + q20_scared_no_reason) <= 7 THEN 'Moderate'
            WHEN (q2_dry_mouth + q4_breathing_difficulty + q7_trembling + q9_worried_panic +
                  q15_close_to_panic + q19_heart_action + q20_scared_no_reason) <= 9 THEN 'Severe'
            ELSE 'Extremely Severe'
        END
    ) STORED,

    stress_severity VARCHAR(20) GENERATED ALWAYS AS (
        CASE
            WHEN (q1_hard_to_wind_down + q6_over_react + q8_nervous_energy + q11_getting_agitated +
                  q12_difficult_relax + q14_intolerant_delays + q18_rather_touchy) <= 7 THEN 'Normal'
            WHEN (q1_hard_to_wind_down + q6_over_react + q8_nervous_energy + q11_getting_agitated +
                  q12_difficult_relax + q14_intolerant_delays + q18_rather_touchy) <= 9 THEN 'Mild'
            WHEN (q1_hard_to_wind_down + q6_over_react + q8_nervous_energy + q11_getting_agitated +
                  q12_difficult_relax + q14_intolerant_delays + q18_rather_touchy) <= 12 THEN 'Moderate'
            WHEN (q1_hard_to_wind_down + q6_over_react + q8_nervous_energy + q11_getting_agitated +
                  q12_difficult_relax + q14_intolerant_delays + q18_rather_touchy) <= 16 THEN 'Severe'
            ELSE 'Extremely Severe'
        END
    ) STORED,

    -- Form Status
    active BOOLEAN DEFAULT TRUE,
    status VARCHAR(50) DEFAULT 'draft', -- draft, completed

    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by INTEGER REFERENCES users(id),
    updated_by INTEGER REFERENCES users(id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_psych_exam_user_id ON psych_exam(user_id);
CREATE INDEX IF NOT EXISTS idx_psych_exam_student_id ON psych_exam(student_id);
CREATE INDEX IF NOT EXISTS idx_psych_exam_assessment_date ON psych_exam(assessment_date);
CREATE INDEX IF NOT EXISTS idx_psych_exam_active ON psych_exam(active);
CREATE INDEX IF NOT EXISTS idx_psych_exam_status ON psych_exam(status);
CREATE INDEX IF NOT EXISTS idx_psych_exam_created_at ON psych_exam(created_at);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_psych_exam_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER trigger_update_psych_exam_updated_at
    BEFORE UPDATE ON psych_exam
    FOR EACH ROW
    EXECUTE FUNCTION update_psych_exam_updated_at();

-- Function to get psych exam assessment with user details
CREATE OR REPLACE FUNCTION get_psych_exam_assessment(p_user_id INTEGER)
RETURNS TABLE(
    id INTEGER,
    user_id INTEGER,
    student_id VARCHAR(50),
    username VARCHAR(100),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(255),
    program VARCHAR(100),
    major VARCHAR(100),
    assessment_date DATE,
    q1_hard_to_wind_down INTEGER,
    q2_dry_mouth INTEGER,
    q3_no_positive_feeling INTEGER,
    q4_breathing_difficulty INTEGER,
    q5_difficult_initiative INTEGER,
    q6_over_react INTEGER,
    q7_trembling INTEGER,
    q8_nervous_energy INTEGER,
    q9_worried_panic INTEGER,
    q10_nothing_to_look_forward INTEGER,
    q11_getting_agitated INTEGER,
    q12_difficult_relax INTEGER,
    q13_down_hearted INTEGER,
    q14_intolerant_delays INTEGER,
    q15_close_to_panic INTEGER,
    q16_unable_enthusiastic INTEGER,
    q17_not_worth_much INTEGER,
    q18_rather_touchy INTEGER,
    q19_heart_action INTEGER,
    q20_scared_no_reason INTEGER,
    q21_life_meaningless INTEGER,
    depression_score INTEGER,
    anxiety_score INTEGER,
    stress_score INTEGER,
    depression_severity VARCHAR(20),
    anxiety_severity VARCHAR(20),
    stress_severity VARCHAR(20),
    active BOOLEAN,
    status VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id, d.user_id, d.student_id, u.username, u.first_name, u.last_name,
        d.full_name, d.program, d.major, d.assessment_date,
        d.q1_hard_to_wind_down, d.q2_dry_mouth, d.q3_no_positive_feeling,
        d.q4_breathing_difficulty, d.q5_difficult_initiative, d.q6_over_react,
        d.q7_trembling, d.q8_nervous_energy, d.q9_worried_panic,
        d.q10_nothing_to_look_forward, d.q11_getting_agitated, d.q12_difficult_relax,
        d.q13_down_hearted, d.q14_intolerant_delays, d.q15_close_to_panic,
        d.q16_unable_enthusiastic, d.q17_not_worth_much, d.q18_rather_touchy,
        d.q19_heart_action, d.q20_scared_no_reason, d.q21_life_meaningless,
        d.depression_score, d.anxiety_score, d.stress_score,
        d.depression_severity, d.anxiety_severity, d.stress_severity,
        d.active, d.status, d.created_at, d.updated_at
    FROM psych_exam d
    JOIN users u ON d.user_id = u.id
    WHERE d.user_id = p_user_id;
END;
$$;

-- Function to get all psych exam assessments (for admin/counselor)
CREATE OR REPLACE FUNCTION get_all_psych_exam_assessments()
RETURNS TABLE(
    id INTEGER,
    user_id INTEGER,
    student_id VARCHAR(50),
    username VARCHAR(100),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(255),
    program VARCHAR(100),
    major VARCHAR(100),
    assessment_date DATE,
    depression_score INTEGER,
    anxiety_score INTEGER,
    stress_score INTEGER,
    depression_severity VARCHAR(20),
    anxiety_severity VARCHAR(20),
    stress_severity VARCHAR(20),
    active BOOLEAN,
    status VARCHAR(50),
    created_at TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id, d.user_id, d.student_id, u.username, u.first_name, u.last_name,
        d.full_name, d.program, d.major, d.assessment_date,
        d.depression_score, d.anxiety_score, d.stress_score,
        d.depression_severity, d.anxiety_severity, d.stress_severity,
        d.active, d.status, d.created_at
    FROM psych_exam d
    JOIN users u ON d.user_id = u.id
    ORDER BY d.created_at DESC;
END;
$$;

-- Procedure to insert/update psych exam assessment
CREATE OR REPLACE PROCEDURE save_psych_exam_assessment(
    p_user_id INTEGER,
    p_student_id VARCHAR(50),
    p_full_name VARCHAR(255) DEFAULT NULL,
    p_program VARCHAR(100) DEFAULT NULL,
    p_major VARCHAR(100) DEFAULT NULL,
    p_q1 INTEGER DEFAULT NULL, p_q2 INTEGER DEFAULT NULL, p_q3 INTEGER DEFAULT NULL,
    p_q4 INTEGER DEFAULT NULL, p_q5 INTEGER DEFAULT NULL, p_q6 INTEGER DEFAULT NULL,
    p_q7 INTEGER DEFAULT NULL, p_q8 INTEGER DEFAULT NULL, p_q9 INTEGER DEFAULT NULL,
    p_q10 INTEGER DEFAULT NULL, p_q11 INTEGER DEFAULT NULL, p_q12 INTEGER DEFAULT NULL,
    p_q13 INTEGER DEFAULT NULL, p_q14 INTEGER DEFAULT NULL, p_q15 INTEGER DEFAULT NULL,
    p_q16 INTEGER DEFAULT NULL, p_q17 INTEGER DEFAULT NULL, p_q18 INTEGER DEFAULT NULL,
    p_q19 INTEGER DEFAULT NULL, p_q20 INTEGER DEFAULT NULL, p_q21 INTEGER DEFAULT NULL,
    p_status VARCHAR(50) DEFAULT 'draft',
    p_created_by INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO psych_exam (
        user_id, student_id, full_name, program, major,
        q1_hard_to_wind_down, q2_dry_mouth, q3_no_positive_feeling,
        q4_breathing_difficulty, q5_difficult_initiative, q6_over_react,
        q7_trembling, q8_nervous_energy, q9_worried_panic,
        q10_nothing_to_look_forward, q11_getting_agitated, q12_difficult_relax,
        q13_down_hearted, q14_intolerant_delays, q15_close_to_panic,
        q16_unable_enthusiastic, q17_not_worth_much, q18_rather_touchy,
        q19_heart_action, q20_scared_no_reason, q21_life_meaningless,
        status, created_by, updated_by
    ) VALUES (
        p_user_id, p_student_id, p_full_name, p_program, p_major,
        p_q1, p_q2, p_q3, p_q4, p_q5, p_q6, p_q7, p_q8, p_q9, p_q10,
        p_q11, p_q12, p_q13, p_q14, p_q15, p_q16, p_q17, p_q18, p_q19, p_q20, p_q21,
        p_status, p_created_by, p_created_by
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        full_name = COALESCE(p_full_name, psych_exam.full_name),
        program = COALESCE(p_program, psych_exam.program),
        major = COALESCE(p_major, psych_exam.major),
        q1_hard_to_wind_down = COALESCE(p_q1, psych_exam.q1_hard_to_wind_down),
        q2_dry_mouth = COALESCE(p_q2, psych_exam.q2_dry_mouth),
        q3_no_positive_feeling = COALESCE(p_q3, psych_exam.q3_no_positive_feeling),
        q4_breathing_difficulty = COALESCE(p_q4, psych_exam.q4_breathing_difficulty),
        q5_difficult_initiative = COALESCE(p_q5, psych_exam.q5_difficult_initiative),
        q6_over_react = COALESCE(p_q6, psych_exam.q6_over_react),
        q7_trembling = COALESCE(p_q7, psych_exam.q7_trembling),
        q8_nervous_energy = COALESCE(p_q8, psych_exam.q8_nervous_energy),
        q9_worried_panic = COALESCE(p_q9, psych_exam.q9_worried_panic),
        q10_nothing_to_look_forward = COALESCE(p_q10, psych_exam.q10_nothing_to_look_forward),
        q11_getting_agitated = COALESCE(p_q11, psych_exam.q11_getting_agitated),
        q12_difficult_relax = COALESCE(p_q12, psych_exam.q12_difficult_relax),
        q13_down_hearted = COALESCE(p_q13, psych_exam.q13_down_hearted),
        q14_intolerant_delays = COALESCE(p_q14, psych_exam.q14_intolerant_delays),
        q15_close_to_panic = COALESCE(p_q15, psych_exam.q15_close_to_panic),
        q16_unable_enthusiastic = COALESCE(p_q16, psych_exam.q16_unable_enthusiastic),
