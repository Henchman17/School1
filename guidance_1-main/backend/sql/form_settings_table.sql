-- Create form_settings table for global form enable/disable
CREATE TABLE IF NOT EXISTS form_settings (
    id SERIAL PRIMARY KEY,
    scrf_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    routine_interview_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    good_moral_request_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    guidance_scheduling_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default settings if not exists
INSERT INTO form_settings (scrf_enabled, routine_interview_enabled, good_moral_request_enabled, guidance_scheduling_enabled)
SELECT TRUE, TRUE, TRUE, TRUE
WHERE NOT EXISTS (SELECT 1 FROM form_settings);
