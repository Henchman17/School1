## TODO: Implement 4-Head Approval System for Good Moral Requests

### Database Schema Changes
- [x] Create good_moral_requests table with approval workflow fields
- [x] Create head_approvals table for tracking individual head approvals
- [x] Create head_roles table for managing head positions
- [x] Add approval_sequence and approval_status to existing tables
- [x] Create head_assignments table for linking users to roles

### Backend API Endpoints
- [x] Update student routes for good moral request submission
- [x] Create head routes for approval/rejection actions
- [x] Update admin routes for final approval and certificate generation
- [x] Add notification endpoints for approval status updates

### Frontend UI Modifications
- [x] Update student good moral request page to show approval status
- [x] Modify head dashboard to show pending approvals
- [x] Update admin good moral requests page with approval workflow
- [x] Add approval sequence indicators in UI

### Certificate Generation
- [x] Implement PDF certificate generation using Syncfusion
- [x] Add certificate template with approval signatures
- [x] Update admin interface for certificate download

### Notification System
- [ ] Implement real-time notifications for approval status
- [ ] Add email notifications for approval updates
- [ ] Update notification badges in dashboards

### Testing
- [ ] Test complete approval workflow from student to admin
- [ ] Verify certificate generation and download
- [ ] Test notification system
- [ ] Validate role-based access controls
