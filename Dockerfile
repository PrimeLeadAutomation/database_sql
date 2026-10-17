FROM mysql:8.0

# MySQL executes .sql files in this directory during first initialization.
COPY primelead_automation_script.sql /docker-entrypoint-initdb.d/01-primelead-automation.sql
