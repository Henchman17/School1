# Student HTTP to Supabase Migration

## Overview
Migrate all HTTP API calls in student/*.dart files to direct Supabase operations.

## Files to Migrate

### 1. lib/student/student_panel.dart
- **Method**: `_fetchApprovedAppointments()`
- **Current**: HTTP GET to `/api/appointments/approved?user_id={userId}`
- **Migration**: Use Supabase query on `appointments` table with status filter

### 2. lib/student/guidance_scheduling_page.dart
- **Methods**:
  - `_fetchAppointments()`: HTTP GET to `/api/appointments?user_id={userId}`
  - `_fetchCourses()`: HTTP GET to `/api/courses`
  - `_submitForm()`: HTTP POST to `/api/appointments`
  - `_updateAppointment()`: HTTP PUT to `/api/appointments/{id}`
  - `_deleteAppointment()`: HTTP DELETE to `/api/appointments/{id}?user_id={userId}`
  - `_approveAppointment()`: HTTP PUT to `/api/appointments/{id}/approve`
- **Migration**: Direct Supabase operations on `appointments` and `courses` tables

### 3. lib/student/scrf_page.dart
- **Methods**:
  - `_fetchPrograms()`: HTTP GET to `/api/courses`
  - `_submitForm()`: HTTP POST/PUT to `/api/scrf`
- **Migration**: Direct Supabase operations on `courses` and `scrf_records` tables

### 4. lib/student/good_moral_request.dart
- **Method**: `_submitGoodMoralRequest()`
- **Current**: HTTP POST to `/api/counselor/good-moral-requests`
- **Migration**: Direct Supabase insert into `good_moral_requests` table

### 5. lib/student/routine_interview_page.dart
- **Method**: `_submitForm()`
- **Current**: No HTTP call (was placeholder)
- **Migration**: Direct Supabase insert into `routine_interviews` table

## Migration Steps

### Step 1: Update Imports
- Remove `package:http/http.dart` imports
- Ensure `package:supabase_flutter/supabase_flutter.dart` is imported
- Remove `dart:convert` if only used for HTTP

### Step 2: Replace HTTP Calls with Supabase Queries

#### Appointments Table Operations
- Fetch appointments: `supabase.from('appointments').select().eq('user_id', userId)`
- Create appointment: `supabase.from('appointments').insert(data)`
- Update appointment: `supabase.from('appointments').update(data).eq('id', id)`
- Delete appointment: `supabase.from('appointments').delete().eq('id', id)`

#### Courses Table Operations
- Fetch courses: `supabase.from('courses').select()`

#### SCRF Records Operations
- Fetch existing SCRF: `supabase.from('scrf_records').select().eq('user_id', userId)`
- Insert/Update SCRF: `supabase.from('scrf_records').upsert(data)`

#### Good Moral Requests Operations
- Insert request: `supabase.from('good_moral_requests').insert(data)`

### Step 3: Error Handling
- Replace HTTP status code checks with Supabase error handling
- Use try-catch for Supabase exceptions

### Step 4: Data Transformation
- Remove JSON encoding/decoding
- Work directly with Dart objects for Supabase

## Testing
- Test each migrated method
- Verify data consistency with existing backend
- Test error scenarios

## Completion Checklist
- [x] student_panel.dart migrated (Migrated to Supabase)
- [x] guidance_scheduling_page.dart migrated (Migrated to Supabase)
- [x] scrf_page.dart migrated (Migrated to Supabase)
- [x] good_moral_request.dart migrated (Migrated to Supabase)
- [x] routine_interview_page.dart migrated (Migrated to Supabase)
- [x] All imports cleaned up
- [x] Testing completed
