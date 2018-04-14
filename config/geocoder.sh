cd /cartodb

rake cartodb:db:create_user --trace SUBDOMAIN="geocoder" \
	PASSWORD="pass1234" ADMIN_PASSWORD="pass1234" \
	EMAIL="geocoder@example.com"

# # Update your quota to 100GB
echo "--- Updating quota to 100GB"
rake cartodb:db:set_user_quota[geocoder,102400]

# # Allow unlimited tables to be created
echo "--- Allowing unlimited tables creation"
rake cartodb:db:set_unlimited_table_quota[geocoder]

GEOCODER_DB=`echo "SELECT database_name FROM users WHERE username='geocoder'" | psql -U postgres -t carto_db_development`
psql -U postgres $GEOCODER_DB < /cartodb/script/geocoder_server.sql

# Import observatory test dataset
psql -U postgres -d $GEOCODER_DB -f /observatory-extension/src/pg/test/fixtures/load_fixtures.sql
# Setup permissions for observatory
psql -U postgres -d $GEOCODER_DB -c "BEGIN;CREATE EXTENSION IF NOT EXISTS observatory VERSION 'development'; COMMIT" -e
psql -U postgres -d $GEOCODER_DB -c "BEGIN;GRANT SELECT ON ALL TABLES IN SCHEMA cdb_observatory TO geocoder_api; COMMIT" -e
psql -U postgres -d $GEOCODER_DB -c "BEGIN;GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA cdb_observatory TO geocoder_api; COMMIT" -e
psql -U postgres -d $GEOCODER_DB -c "BEGIN;GRANT SELECT ON ALL TABLES IN SCHEMA observatory TO geocoder_api; COMMIT" -e
psql -U postgres -d $GEOCODER_DB -c "BEGIN;GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA observatory TO geocoder_api; COMMIT" -e

# Setup dataservices client
# dev user
USER_DB=`echo "SELECT database_name FROM users WHERE username='development'" | psql -U postgres -t carto_db_development`
echo "CREATE EXTENSION cdb_dataservices_client;" | psql -U postgres $USER_DB
echo "SELECT CDB_Conf_SetConf('user_config', '{"'"is_organization"'": false, "'"entity_name"'": "'"development"'"}');" | psql -U postgres $USER_DB
echo -e "SELECT CDB_Conf_SetConf('geocoder_server_config', '{ \"connection_str\": \"host=localhost port=5432 dbname=${GEOCODER_DB# } user=postgres\"}');" | psql -U postgres $USER_DB
rake cartodb:services:set_user_quota['development',geocoding,100000]