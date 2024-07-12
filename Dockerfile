# Use CKAN base image
FROM openknowledge/ckan-dev:2.9

WORKDIR /srv/app

# Install system dependencies
#RUN apk update && apk add jpeg-dev git

RUN pip install setuptools==44.1.0
RUN pip install --upgrade pip==23.2.1

# Uninstall current CKAN
RUN pip uninstall -y ckan

# Craziness from circleci
RUN git --git-dir=/srv/app/src/ckan/.git --work-tree=/srv/app/src/ckan/ remote add canada https://github.com/open-data/ckan.git
RUN git --git-dir=/srv/app/src/ckan/.git --work-tree=/srv/app/src/ckan/ fetch canada canada-py3
RUN git --git-dir=/srv/app/src/ckan/.git --work-tree=/srv/app/src/ckan/ checkout -b canada-py3 canada/canada-py3
RUN git --git-dir=/srv/app/src/ckan/.git --work-tree=/srv/app/src/ckan/ pull


# Dependencies
RUN pip install -e /srv/app/src/ckan/ -r /srv/app/src/ckan/requirements.txt -r /srv/app/src/ckan/dev-requirements.txt
RUN pip install -e 'git+https://github.com/ckan/ckanapi.git#egg=ckanapi' -r 'https://raw.githubusercontent.com/ckan/ckanapi/master/requirements.txt'
RUN pip install -e 'git+https://github.com/gc-performance/ckanext-canada.git#egg=ckanext-canada' -r 'https://raw.githubusercontent.com/gc-performance/ckanext-canada/master/requirements.txt' -r 'https://raw.githubusercontent.com/gc-performance/ckanext-canada/master/test-requirements.txt'
RUN pip install -e 'git+https://github.com/ckan/ckanext-fluent.git#egg=ckanext-fluent' -r 'https://raw.githubusercontent.com/ckan/ckanext-fluent/master/requirements.txt'
RUN pip install -e 'git+https://github.com/open-data/ckanext-recombinant.git#egg=ckanext-recombinant' -r 'https://raw.githubusercontent.com/open-data/ckanext-recombinant/master/requirements.txt'
RUN pip install -e 'git+https://github.com/ckan/ckanext-scheming.git#egg=ckanext-scheming'
RUN pip install -e 'git+https://github.com/open-data/ckanext-validation.git@canada-py3#egg=ckanext-validation' -r 'https://raw.githubusercontent.com/open-data/ckanext-validation/canada-py3/requirements.txt' -r 'https://raw.githubusercontent.com/open-data/ckanext-validation/canada-py3/dev-requirements.txt'
RUN pip install -e 'git+https://github.com/open-data/ckanext-xloader.git@canada-py3#egg=ckanext-xloader' -r 'https://raw.githubusercontent.com/open-data/ckanext-xloader/canada-py3/requirements.txt' -r 'https://raw.githubusercontent.com/open-data/ckanext-xloader/canada-py3/dev-requirements.txt'
RUN pip install -e 'git+https://github.com/ckan/ckantoolkit.git#egg=ckantoolkit' -r 'https://raw.githubusercontent.com/ckan/ckantoolkit/master/requirements.txt'
RUN pip install -e 'git+https://github.com/open-data/goodtables.git@canada-py3#egg=goodtables' -r 'https://raw.githubusercontent.com/open-data/goodtables/canada-py3/requirements.txt'
RUN pip install -e 'git+https://github.com/open-data/ckanext-security.git@canada-py3#egg=ckanext-security' -r 'https://raw.githubusercontent.com/open-data/ckanext-security/canada-py3/requirements.txt'
RUN find /srv/app/ -name '*.pyc' -delete

# CKAN setup

ARG PGHOST
ARG PGUSER
ARG PGPASSWORD
ARG PGPORT
ARG PGDATABASE

RUN rm ./ckan.ini ./who.ini
RUN ln -s /srv/app/src/ckan-canada/test-core.ini ./ckan.ini
RUN ln -s /srv/app/src/ckan/test-core.ini ./test-core.ini
RUN ln -s /srv/app/src/ckan/who.ini ./who.ini
# RUN mkdir -p ./links/ckanext/datastore/tests/ && ln -s /srv/app/src/ckan/ckanext/datastore/tests/allowed_functions.txt ./links/ckanext/datastore/tests/allowed_functions.txt
#RUN mkdir -p ./links/ckan/bin/postgres_init/ && ln -s /srv/app/src/ckan/bin/postgres_init/1_create_ckan_db.sh ./links/ckan/bin/postgres_init/1_create_ckan_db.sh && ln -s /srv/app/src/ckan/bin/postgres_init/2_create_ckan_datastore_db.sh ./links/ckan/bin/postgres_init/2_create_ckan_datastore_db.sh
#
#
#RUN . ./links/ckan/bin/postgres_init/1_create_ckan_db.sh
#RUN . ./links/ckan/bin/postgres_init/2_create_ckan_datastore_db.sh
RUN ckan -c ckan.ini db init
RUN ckan -c ckan.ini datastore set-permissions | psql -U postgres --set ON_ERROR_STOP=1
RUN ckan -c ckan.ini canada update-triggers
RUN ckan -c ckan.ini recombinant create-triggers -a
RUN python3 /srv/app/src/ckan-canada/bin/download_country.py

#
## # Generate CKAN config file
## RUN ckan generate config ckan.ini
## 
## # Set up storage
## RUN mkdir -p /workspace/data \
##     && ckan config-tool ckan.ini "ckan.storage_path=/workspace/data"
## 
## # Set up site URL, assuming environment variables are set for CODESPACE_NAME and GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN
## ARG CKAN_SITE_URL
## RUN ckan config-tool ckan.ini "ckan.site_url=${CKAN_SITE_URL}"
## 
## # # Initialize the database
## # RUN ckan db init
## # 
## # # Create sysadmin user
## # RUN ckan user add ckan_admin email=admin@example.com password=test1234 \
## #     && ckan sysadmin add ckan_admin
## # 
## # ## Set up DataStore + DataPusher
## # #RUN API_TOKEN=$(ckan user token add ckan_admin datapusher | tail -n 1 | tr -d '\t') \
## # #    && ckan config-tool ckan.ini "ckan.datapusher.api_token=${API_TOKEN}" \
## # #    && ckan config-tool ckan.ini \
## # #        "ckan.datastore.write_url=postgresql://ckan_default:pass@localhost/datastore_default" \
## # #        "ckan.datastore.read_url=postgresql://datastore_default:pass@localhost/datastore_default" \
## # #        "ckan.datapusher.url=http://localhost:8800" \
## # #        "ckan.datapusher.callback_url_base=http://localhost:5000" \
## # #        "ckan.plugins=activity datastore datapusher datatables_view"
## # 
## # # Set permissions for DataStore
## # RUN ckan datastore set-permissions | psql $(grep ckan.datastore.write_url ckan.ini | awk -F= '{print $2}')

## Expose port 5000 for web interface
#EXPOSE 5000

#T Run CKAN

#ENTRYPOINT ["bash"]
ENTRYPOINT ["tail", "-f", "/dev/null"]
# CMD ["ckan", "run", "--host", "0.0.0.0"]
