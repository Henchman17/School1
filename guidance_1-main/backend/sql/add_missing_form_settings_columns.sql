-- Add missing columns to form_settings table
ALTER TABLE form_settings ADD COLUMN IF NOT EXISTS good_moral_request_enabled BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE form_settings ADD COLUMN IF NOT EXISTS guidance_scheduling_enabled BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE form_settings ADD COLUMN IF NOT EXISTS dass21_enabled BOOLEAN NOT NULL DEFAULT FALSE;

-- Update existing records to have default values
UPDATE form_settings SET
  good_moral_request_enabled = TRUE,
  guidance_scheduling_enabled = TRUE,
  dass21_enabled = FALSE
WHERE good_moral_request_enabled IS NULL
   OR guidance_scheduling_enabled IS NULL
   OR dass21_enabled IS NULL;
