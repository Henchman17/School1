-- Admin Audit Logs Table
-- Tracks all administrative actions for compliance and security

CREATE TABLE IF NOT EXISTS admin_audit_logs (
    id SERIAL PRIMARY KEY,
    admin_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL, -- e.g., 'CREATE_USER', 'UPDATE_APPOINTMENT', 'DELETE_USER'
    target_table VARCHAR(50), -- e.g., 'users', 'appointments'
    target_id INTEGER, -- ID of the affected record
    old_values JSONB, -- Previous values (for updates/deletes)
    new_values JSONB, -- New values (for creates/updates)
    ip_address VARCHAR(45), -- IPv4/IPv6 address
    user_agent TEXT, -- Browser/client info
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    notes TEXT -- Additional context
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_admin_id ON admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_action ON admin_audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_timestamp ON admin_audit_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_target ON admin_audit_logs(target_table, target_id);

-- Insert sample audit log entries
INSERT INTO admin_audit_logs (admin_id, action, target_table, target_id, notes, timestamp) VALUES
((SELECT id FROM users WHERE role = 'admin' LIMIT 1), 'SYSTEM_STARTUP', NULL, NULL, 'System initialization', NOW()),
((SELECT id FROM users WHERE role = 'admin' LIMIT 1), 'USER_LOGIN', 'users', (SELECT id FROM users WHERE role = 'admin' LIMIT 1), 'Admin login successful', NOW() - INTERVAL '1 hour')
ON CONFLICT DO NOTHING;
