-- Good Moral Requests Table with 4-Head Approval Workflow
-- This table stores good moral certificate requests with approval workflow

CREATE TABLE IF NOT EXISTS good_moral_requests (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_name VARCHAR(255) NOT NULL,
    student_number VARCHAR(50) NOT NULL,
    course VARCHAR(255),
    purpose TEXT NOT NULL,
    address TEXT,
    school_year VARCHAR(50),
    edst VARCHAR(255),
    gor VARCHAR(255),
    ocr_data JSONB, -- Store OCR extracted data

    -- Approval workflow fields
    approval_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected', 'cancelled')),
    current_approval_step INTEGER DEFAULT 1 CHECK (current_approval_step >= 1 AND current_approval_step <= 4),
    total_approvals_needed INTEGER DEFAULT 4,
    approvals_received INTEGER DEFAULT 0,

    -- Certificate generation
    certificate_path TEXT,
    certificate_generated_at TIMESTAMP,

    -- Admin final approval
    admin_approved BOOLEAN DEFAULT FALSE,
    admin_approved_at TIMESTAMP,
    admin_approved_by INTEGER REFERENCES users(id),

    -- Rejection details
    rejection_reason TEXT,
    rejected_at TIMESTAMP,
    rejected_by INTEGER REFERENCES users(id),

    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by INTEGER REFERENCES users(id),
    updated_by INTEGER REFERENCES users(id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_good_moral_requests_student_id ON good_moral_requests(student_id);
CREATE INDEX IF NOT EXISTS idx_good_moral_requests_status ON good_moral_requests(approval_status);
CREATE INDEX IF NOT EXISTS idx_good_moral_requests_current_step ON good_moral_requests(current_approval_step);
CREATE INDEX IF NOT EXISTS idx_good_moral_requests_created_at ON good_moral_requests(created_at);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_good_moral_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER trigger_update_good_moral_requests_updated_at
    BEFORE UPDATE ON good_moral_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_good_moral_requests_updated_at();

-- Head Approvals Table - tracks individual head approvals
CREATE TABLE IF NOT EXISTS head_approvals (
    id SERIAL PRIMARY KEY,
    request_id INTEGER NOT NULL REFERENCES good_moral_requests(id) ON DELETE CASCADE,
    head_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    head_role_id INTEGER NOT NULL REFERENCES head_roles(id) ON DELETE CASCADE,
    approval_sequence INTEGER NOT NULL CHECK (approval_sequence >= 1 AND approval_sequence <= 4),

    -- Approval details
    approved BOOLEAN NOT NULL,
    approval_notes TEXT,
    approved_at TIMESTAMP,

    -- Rejection details (if applicable)
    rejection_reason TEXT,
    rejected_at TIMESTAMP,

    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_head_approvals_request_id ON head_approvals(request_id);
CREATE INDEX IF NOT EXISTS idx_head_approvals_head_user_id ON head_approvals(head_user_id);
CREATE INDEX IF NOT EXISTS idx_head_approvals_sequence ON head_approvals(approval_sequence);
CREATE INDEX IF NOT EXISTS idx_head_approvals_approved ON head_approvals(approved);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_head_approvals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER trigger_update_head_approvals_updated_at
    BEFORE UPDATE ON head_approvals
    FOR EACH ROW
    EXECUTE FUNCTION update_head_approvals_updated_at();

-- Function to get approval status for a request
CREATE OR REPLACE FUNCTION get_request_approval_status(p_request_id INTEGER)
RETURNS TABLE(
    total_heads INTEGER,
    approved_count INTEGER,
    rejected_count INTEGER,
    pending_count INTEGER,
    current_step INTEGER,
    next_required_head_user_id INTEGER,
    next_required_head_name VARCHAR(255),
    next_required_role_name VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_heads INTEGER := 4;
    v_approved_count INTEGER;
    v_rejected_count INTEGER;
    v_pending_count INTEGER;
    v_current_step INTEGER;
    v_next_head_user_id INTEGER;
    v_next_head_name VARCHAR(255);
    v_next_role_name VARCHAR(100);
BEGIN
    -- Get current approval counts
    SELECT
        COUNT(*) FILTER (WHERE approved = TRUE),
        COUNT(*) FILTER (WHERE approved = FALSE),
        v_total_heads - COUNT(*)
    INTO v_approved_count, v_rejected_count, v_pending_count
    FROM head_approvals
    WHERE request_id = p_request_id;

    -- Get current step from request
    SELECT current_approval_step INTO v_current_step
    FROM good_moral_requests
    WHERE id = p_request_id;

    -- If there are rejections, stop the process
    IF v_rejected_count > 0 THEN
        v_next_head_user_id := NULL;
        v_next_head_name := NULL;
        v_next_role_name := NULL;
    ELSE
        -- Get next required head
        SELECT ha.user_id, CONCAT(u.first_name, ' ', u.last_name), hr.role_name
        INTO v_next_head_user_id, v_next_head_name, v_next_role_name
        FROM head_assignments ha
        JOIN users u ON ha.user_id = u.id
        JOIN head_roles hr ON ha.head_role_id = hr.id
        WHERE ha.is_active = TRUE
          AND hr.approval_sequence = v_current_step
          AND hr.is_active = TRUE;
    END IF;

    RETURN QUERY SELECT
        v_total_heads, v_approved_count, v_rejected_count, v_pending_count,
        v_current_step, v_next_head_user_id, v_next_head_name, v_next_role_name;
END;
$$;

-- Function to process head approval
CREATE OR REPLACE FUNCTION process_head_approval(
    p_request_id INTEGER,
    p_head_user_id INTEGER,
    p_approved BOOLEAN,
    p_notes TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_step INTEGER;
    v_head_role_id INTEGER;
    v_approval_sequence INTEGER;
    v_existing_approval_id INTEGER;
    v_rejection_reason TEXT;
    v_result TEXT;
BEGIN
    -- Get current step and validate head can approve
    SELECT current_approval_step INTO v_current_step
    FROM good_moral_requests
    WHERE id = p_request_id;

    -- Get head's role and sequence
    SELECT ha.head_role_id, hr.approval_sequence
    INTO v_head_role_id, v_approval_sequence
    FROM head_assignments ha
    JOIN head_roles hr ON ha.head_role_id = hr.id
    WHERE ha.user_id = p_head_user_id
      AND ha.is_active = TRUE
      AND hr.is_active = TRUE;

    -- Validate head can approve this step
    IF v_approval_sequence != v_current_step THEN
        RETURN 'ERROR: Not authorized to approve this step';
    END IF;

    -- Check if approval already exists
    SELECT id INTO v_existing_approval_id
    FROM head_approvals
    WHERE request_id = p_request_id AND head_user_id = p_head_user_id;

    IF v_existing_approval_id IS NOT NULL THEN
        RETURN 'ERROR: Approval already submitted for this step';
    END IF;

    -- Insert approval/rejection
    INSERT INTO head_approvals (
        request_id, head_user_id, head_role_id, approval_sequence,
        approved, approval_notes, approved_at,
        rejection_reason, rejected_at
    ) VALUES (
        p_request_id, p_head_user_id, v_head_role_id, v_approval_sequence,
        p_approved,
        CASE WHEN p_approved THEN p_notes ELSE NULL END,
        CASE WHEN p_approved THEN NOW() ELSE NULL END,
        CASE WHEN NOT p_approved THEN p_notes ELSE NULL END,
        CASE WHEN NOT p_approved THEN NOW() ELSE NULL END
    );

    -- Update request status
    IF p_approved THEN
        -- Check if all approvals received
        IF v_current_step >= 4 THEN
            -- All heads approved, ready for admin
            UPDATE good_moral_requests
            SET approvals_received = approvals_received + 1,
                approval_status = 'approved',
                updated_at = NOW()
            WHERE id = p_request_id;
            v_result := 'SUCCESS: All head approvals received. Ready for admin final approval.';
        ELSE
            -- Move to next step
            UPDATE good_moral_requests
            SET current_approval_step = current_approval_step + 1,
                approvals_received = approvals_received + 1,
                updated_at = NOW()
            WHERE id = p_request_id;
            v_result := 'SUCCESS: Approved. Moved to next approval step.';
        END IF;
    ELSE
        -- Rejected - end the process
        UPDATE good_moral_requests
        SET approval_status = 'rejected',
            rejection_reason = p_notes,
            rejected_at = NOW(),
            rejected_by = p_head_user_id,
            updated_at = NOW()
        WHERE id = p_request_id;
        v_result := 'REJECTED: Request rejected by head.';
    END IF;

    RETURN v_result;
END;
$$;

-- Function to get requests pending for specific head
CREATE OR REPLACE FUNCTION get_pending_requests_for_head(p_head_user_id INTEGER)
RETURNS TABLE(
    request_id INTEGER,
    student_name VARCHAR(255),
    student_number VARCHAR(50),
    course VARCHAR(255),
    purpose TEXT,
    created_at TIMESTAMP,
    approval_step INTEGER,
    head_role_name VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        gmr.id, gmr.student_name, gmr.student_number, gmr.course,
        gmr.purpose, gmr.created_at, gmr.current_approval_step, hr.role_name
    FROM good_moral_requests gmr
    JOIN head_assignments ha ON ha.head_role_id IN (
        SELECT head_role_id FROM head_assignments
        WHERE user_id = p_head_user_id AND is_active = TRUE
    )
    JOIN head_roles hr ON ha.head_role_id = hr.id
    WHERE gmr.approval_status = 'pending'
      AND gmr.current_approval_step = hr.approval_sequence
      AND ha.is_active = TRUE
      AND hr.is_active = TRUE
      AND NOT EXISTS (
          SELECT 1 FROM head_approvals ha2
          WHERE ha2.request_id = gmr.id AND ha2.head_user_id = p_head_user_id
      );
END;
$$;

-- Function to get complete request details with approval history
CREATE OR REPLACE FUNCTION get_request_with_approval_history(p_request_id INTEGER)
RETURNS TABLE(
    request_data JSONB,
    approval_history JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        jsonb_build_object(
            'id', gmr.id,
            'student_id', gmr.student_id,
            'student_name', gmr.student_name,
            'student_number', gmr.student_number,
            'course', gmr.course,
            'purpose', gmr.purpose,
            'address', gmr.address,
            'school_year', gmr.school_year,
            'ocr_data', gmr.ocr_data,
            'approval_status', gmr.approval_status,
            'current_approval_step', gmr.current_approval_step,
            'approvals_received', gmr.approvals_received,
            'certificate_path', gmr.certificate_path,
            'admin_approved', gmr.admin_approved,
            'created_at', gmr.created_at
        ),
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'sequence', ha.approval_sequence,
                    'head_name', CONCAT(u.first_name, ' ', u.last_name),
                    'role_name', hr.role_name,
                    'approved', ha.approved,
                    'notes', COALESCE(ha.approval_notes, ha.rejection_reason),
                    'approved_at', ha.approved_at,
                    'rejected_at', ha.rejected_at
                )
            ) FILTER (WHERE ha.id IS NOT NULL),
            '[]'::jsonb
        )
    FROM good_moral_requests gmr
    LEFT JOIN head_approvals ha ON ha.request_id = gmr.id
    LEFT JOIN users u ON ha.head_user_id = u.id
    LEFT JOIN head_roles hr ON ha.head_role_id = hr.id
    WHERE gmr.id = p_request_id
    GROUP BY gmr.id, gmr.student_id, gmr.student_name, gmr.student_number,
             gmr.course, gmr.purpose, gmr.address, gmr.school_year, gmr.ocr_data,
             gmr.approval_status, gmr.current_approval_step, gmr.approvals_received,
             gmr.certificate_path, gmr.admin_approved, gmr.created_at;
END;
$$;
