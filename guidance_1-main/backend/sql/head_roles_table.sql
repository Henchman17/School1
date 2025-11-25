-- Head Roles Table for managing head positions in approval workflow
-- This table defines the different head positions and their approval sequence

CREATE TABLE IF NOT EXISTS head_roles (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(100) NOT NULL UNIQUE,
    role_description TEXT,
    approval_sequence INTEGER NOT NULL UNIQUE CHECK (approval_sequence >= 1 AND approval_sequence <= 4),
    is_active BOOLEAN DEFAULT TRUE,

    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by INTEGER REFERENCES users(id),
    updated_by INTEGER REFERENCES users(id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_head_roles_approval_sequence ON head_roles(approval_sequence);
CREATE INDEX IF NOT EXISTS idx_head_roles_is_active ON head_roles(is_active);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_head_roles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER trigger_update_head_roles_updated_at
    BEFORE UPDATE ON head_roles
    FOR EACH ROW
    EXECUTE FUNCTION update_head_roles_updated_at();

-- Insert default head roles
INSERT INTO head_roles (role_name, role_description, approval_sequence, is_active) VALUES
('Academic Head', 'Responsible for academic affairs approval', 1, TRUE),
('Student Affairs Head', 'Responsible for student welfare and conduct approval', 2, TRUE),
('Administrative Head', 'Responsible for administrative compliance approval', 3, TRUE),
('Executive Head', 'Responsible for final executive approval', 4, TRUE)
ON CONFLICT (role_name) DO NOTHING;

-- Head Assignments Table - links users to head roles
CREATE TABLE IF NOT EXISTS head_assignments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    head_role_id INTEGER NOT NULL REFERENCES head_roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP NOT NULL DEFAULT NOW(),
    assigned_by INTEGER REFERENCES users(id),
    is_active BOOLEAN DEFAULT TRUE,

    -- Ensure one active assignment per role
    UNIQUE(user_id, head_role_id),

    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_head_assignments_user_id ON head_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_head_assignments_role_id ON head_assignments(head_role_id);
CREATE INDEX IF NOT EXISTS idx_head_assignments_is_active ON head_assignments(is_active);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_head_assignments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER trigger_update_head_assignments_updated_at
    BEFORE UPDATE ON head_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_head_assignments_updated_at();

-- Function to get active head for specific approval step
CREATE OR REPLACE FUNCTION get_active_head_for_step(p_approval_step INTEGER)
RETURNS TABLE(
    user_id INTEGER,
    username VARCHAR(100),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    role_name VARCHAR(100),
    role_description TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id, u.username, u.first_name, u.last_name, u.email,
        hr.role_name, hr.role_description
    FROM head_assignments ha
    JOIN users u ON ha.user_id = u.id
    JOIN head_roles hr ON ha.head_role_id = hr.id
    WHERE ha.is_active = TRUE
      AND hr.approval_sequence = p_approval_step
      AND hr.is_active = TRUE;
END;
$$;

-- Function to get all active heads with their roles
CREATE OR REPLACE FUNCTION get_all_active_heads()
RETURNS TABLE(
    user_id INTEGER,
    username VARCHAR(100),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    role_name VARCHAR(100),
    role_description TEXT,
    approval_sequence INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id, u.username, u.first_name, u.last_name, u.email,
        hr.role_name, hr.role_description, hr.approval_sequence
    FROM head_assignments ha
    JOIN users u ON ha.user_id = u.id
    JOIN head_roles hr ON ha.head_role_id = hr.id
    WHERE ha.is_active = TRUE AND hr.is_active = TRUE
    ORDER BY hr.approval_sequence;
END;
$$;

-- Procedure to assign head role to user
CREATE OR REPLACE PROCEDURE assign_head_role(
    p_user_id INTEGER,
    p_head_role_id INTEGER,
    p_assigned_by INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Deactivate any existing assignment for this user and role
    UPDATE head_assignments
    SET is_active = FALSE, updated_at = NOW()
    WHERE user_id = p_user_id AND head_role_id = p_head_role_id;

    -- Insert new assignment
    INSERT INTO head_assignments (user_id, head_role_id, assigned_by, is_active)
    VALUES (p_user_id, p_head_role_id, p_assigned_by, TRUE);

    RAISE NOTICE 'User ID % assigned to head role ID %', p_user_id, p_head_role_id;
END;
$$;

-- Procedure to remove head role assignment
CREATE OR REPLACE PROCEDURE remove_head_assignment(
    p_user_id INTEGER,
    p_head_role_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE head_assignments
    SET is_active = FALSE, updated_at = NOW()
    WHERE user_id = p_user_id AND head_role_id = p_head_role_id;

    RAISE NOTICE 'Head assignment removed for user ID % and role ID %', p_user_id, p_head_role_id;
END;
$$;
