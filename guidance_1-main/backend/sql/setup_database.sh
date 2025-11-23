#!/bin/bash

echo "Setting up PLSP Guidance Database..."

# Database connection parameters
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="guidance"
DB_USER="admin"
DB_PASSWORD="1254"

echo "Connecting to PostgreSQL database..."
echo "Host: $DB_HOST"
echo "Port: $DB_PORT"
echo "Database: $DB_NAME"
echo "User: $DB_USER"

# Export password for psql
export PGPASSWORD="$DB_PASSWORD"

# Run the complete schema script
echo "Running guidance_database_schema.sql..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f guidance_database_schema.sql

if [ $? -eq 0 ]; then
    echo "Database setup completed successfully!"
    echo "Sample data has been inserted for testing."
else
    echo "Error: Database setup failed!"
    echo "Please check your PostgreSQL connection and try again."
fi

# Unset password
unset PGPASSWORD
