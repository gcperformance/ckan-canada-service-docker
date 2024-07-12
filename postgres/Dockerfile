FROM postgres:14

ADD https://raw.githubusercontent.com/open-data/ckan/canada-py3/bin/postgres_init/1_create_ckan_db.sh /docker-entrypoint-initdb.d/
ADD https://raw.githubusercontent.com/open-data/ckan/canada-py3/bin/postgres_init/2_create_ckan_datastore_db.sh /docker-entrypoint-initdb.d/

EXPOSE 5432
