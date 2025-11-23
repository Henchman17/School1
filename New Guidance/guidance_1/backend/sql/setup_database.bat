@echo off
echo Setting up PLSP Guidance Database...

REM Database connection parameters
set DB_HOST=localhost
set DB_PORT=5432
set DB_NAME=guidance
set DB_USER=admin
set DB_PASSWORD=1254

echo Connecting to PostgreSQL database...
echo Host: %DB_HOST%
echo Port: %DB_PORT%
echo Database: %DB_NAME%
echo User: %DB_USER%

REM Run the complete schema script
echo Running guidance_database_schema.sql...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f guidance_database_schema.sql

if %ERRORLEVEL% EQU 0 (
    echo Database setup completed successfully!
    echo Sample data has been inserted for testing.
) else (
    echo Error: Database setup failed!
    echo Please check your PostgreSQL connection and try again.
)

pause
