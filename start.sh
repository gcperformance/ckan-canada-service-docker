#!/bin/sh

echo "Init db"
./db/initdb.sh

ckan -c ./ckan.ini db init
ckan -c ckan.ini datastore set-permissions | psql --set ON_ERROR_STOP=1

echo "Create admin user"
ckan user add admin email=${CKAN_ADMIN_EMAIL} password=${CKAN_ADMIN_PASSWD}
ckan sysadmin add admin

echo "Create organization"
ckanapi -c ckan.ini action organization_create name=tbs title="Treasury Board" faa_schedule="NA" registry_access="public"  shortform='{ "en": "tbs", "fr": "sct" }' title_translated='{"en": "Treasury Board", "fr": "Secrétariat du Conseil du Trésor"}'

echo "Update canada triggers"
ckan -c ckan.ini canada update-triggers
python3 /srv/app/src/ckanext-canada/bin/download_country.py

echo "Update recombinant triggers"
ckan -c ckan.ini recombinant create-triggers -a

echo "Bring ckan up"
#sudo -u ckan -EH ckan run -H 0.0.0.0
ckan run -H 0.0.0.0
