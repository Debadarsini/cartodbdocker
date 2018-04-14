#!/bin/sh

set -e

SUBDOMAIN="development"
PASSWORD="pass1234"
ADMIN_PASSWORD="pass1234"
EMAIL="dev@example.com"

echo "--- Create '${SUBDOMAIN}' user"
bundle exec rake cartodb:db:create_user --trace SUBDOMAIN="${SUBDOMAIN}" \
	PASSWORD="${PASSWORD}" ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
	EMAIL="${EMAIL}" sync_tables_enabled='t'

# # Update your quota to 100GB
echo "--- Updating quota to 100GB"
bundle exec rake cartodb:db:set_user_quota["${SUBDOMAIN}",102400]

# # Allow unlimited tables to be created
echo "--- Allowing unlimited tables creation"
bundle exec rake cartodb:db:set_unlimited_table_quota["${SUBDOMAIN}"]

# # Allow user to create private tables in addition to public
echo "--- Allowing private tables creation"
bundle exec rake cartodb:db:set_user_private_tables_enabled["${SUBDOMAIN}",'true']

# # Set the account type
echo "--- Setting cartodb account type"
bundle exec rake cartodb:db:set_user_account_type["${SUBDOMAIN}",'[DEDICATED]']


bundle exec rake cartodb:set_custom_limits_for_user["${SUBDOMAIN}","5000000000","500000000","5"]


bundle exec rake cartodb:sync_tables[true]

# Enable sync tables
echo "UPDATE users SET sync_tables_enabled=true WHERE username='${SUBDOMAIN}'" | psql -U postgres -t carto_db_development
#bundle exec rake cartodb:features:add_feature_flag['carto-connectors']
#bundle exec rake cartodb:features:enable_feature_for_all_users['carto-connectors']
#bundle exec rake cartodb:connectors:create_providers

