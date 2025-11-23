-- Update signup fields: rename grade_level to status, section to program, add admission_number
ALTER TABLE users RENAME COLUMN grade_level TO status;
ALTER TABLE users RENAME COLUMN section TO program;
ALTER TABLE users ADD COLUMN admission_number VARCHAR(50);
