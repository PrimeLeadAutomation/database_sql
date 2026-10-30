FROM mysql:8.0

# MySQL executes initialization files in alphabetical order, only on a fresh
# data directory. Keep the schema, migration and seed in this sequence.
COPY primelead_automation_script.sql /docker-entrypoint-initdb.d/01-primelead-automation.sql
COPY database_script_complementation.sql /docker-entrypoint-initdb.d/02-primelead-complementation.sql
COPY massa_dados_primelead.sql /docker-entrypoint-initdb.d/03-primelead-seed.sql
COPY migrate_json_lists.sql /docker-entrypoint-initdb.d/04-primelead-json-lists.sql
