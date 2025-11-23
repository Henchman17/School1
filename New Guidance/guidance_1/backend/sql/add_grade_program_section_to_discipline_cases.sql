-- Add missing grade_level, program, and section columns to discipline_cases table

ALTER TABLE discipline_cases
ADD COLUMN IF NOT EXISTS severity VARCHAR(50),