-- Discipline Cases Query for PLSP Guidance System
-- This query retrieves discipline case information with student and counselor details

SELECT
    dc.id,
    dc.student_id,
    dc.student_name,
    dc.student_number,
    dc.incident_date,
    dc.incident_description,
    dc.incident_location,
    dc.witnesses,
    dc.action_taken,
    dc.severity,
    dc.status,
    dc.admin_notes,
    dc.counselor_id,
    dc.created_at,
    dc.updated_at,
    dc.resolved_at,
    dc.resolved_by,
    u.username as counselor,
    ru.username as resolved_by_name,
    s.grade_level as grade,
    s.program as course,
    s.section
FROM discipline_cases dc
LEFT JOIN users u ON dc.counselor_id = u.id
LEFT JOIN users ru ON dc.resolved_by = ru.id
LEFT JOIN users s ON dc.student_id = s.id
ORDER BY dc.created_at DESC;
