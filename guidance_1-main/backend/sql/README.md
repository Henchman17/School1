# Guidance Database Schema

This directory contains SQL scripts for setting up the database schema for the PLSP Guidance System.

## Files

### `guidance_database_schema.sql`
Complete database schema including:
- `users` table - User accounts with roles (admin, counselor, student)
- `students` table - Student information linked to user accounts
- `appointments` table - Guidance scheduling appointments
- Indexes for performance optimization
- Sample data for testing

### `create_appointments_table.sql`
Standalone script to create only the appointments table for guidance scheduling.

### `user_signup_procedures.sql`
Advanced SQL procedures and functions for user signup with JOIN operations:
- `create_student_user()` - Stored procedure to create user and student records atomically
- `get_user_student_details()` - Function to retrieve joined user and student data
- `student_user_details` - View for complete student information
- `search_students()` - Function to search students by name or email

### `signup_examples.sql`
Practical examples showing how to use the signup procedures and JOIN queries:
- Creating new student users
- Retrieving user details with student information
- Searching and filtering student data
- Verification queries for JOIN relationships

## Database Tables

### Users Table
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'student',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### Students Table
```sql
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_id VARCHAR(50) UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    grade_level VARCHAR(20),
    section VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### Appointments Table
```sql
CREATE TABLE appointments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    counselor_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    appointment_date TIMESTAMP NOT NULL,
    purpose TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

## Usage

1. Connect to your PostgreSQL database
2. Run the complete schema script:
   ```bash
   psql -U your_username -d guidance -f guidance_database_schema.sql
   ```
3. Or run just the appointments table:
   ```bash
   psql -U your_username -d guidance -f create_appointments_table.sql
   ```

## Appointment Status Values

- `scheduled` - Appointment is scheduled but not yet started
- `confirmed` - Appointment has been confirmed by counselor
- `completed` - Appointment has been completed
- `cancelled` - Appointment has been cancelled
- `no_show` - Student did not show up for appointment

## API Integration

The appointments table is used by the Flutter app through the backend API endpoints:
- `POST /api/appointments` - Create new appointment
- `GET /api/appointments` - Get appointments (filtered by student or counselor)
- `PUT /api/appointments/{id}` - Update appointment status
- `DELETE /api/appointments/{id}` - Cancel appointment
