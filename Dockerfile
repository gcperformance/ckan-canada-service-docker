# Use CKAN base image
FROM openknowledge/ckan-dev:2.9

# Set environment variables
ENV PGHOST=postgres \
    PGDATABASE=postgres \
    PGUSER=postgres \
    PGPASSWORD=pass \
    CKAN_POSTGRES_DB=ckan_test \
    CKAN_DATASTORE_POSTGRES_DB=datastore_test \
    CKAN_POSTGRES_USER=ckan_default \
    CKAN_DATASTORE_POSTGRES_READ_USER=datastore_read \
    CKAN_DATASTORE_POSTGRES_WRITE_USER=datastore_write \
    CKAN_POSTGRES_PWD=pass \
    CKAN_DATASTORE_POSTGRES_READ_PWD=pass \
    CKAN_DATASTORE_POSTGRES_WRITE_PWD=pass \
    CKAN_SQLALCHEMY_URL=postgresql://ckan_default:pass@postgres/ckan_test \
    CKAN_DATASTORE_WRITE_URL=postgresql://datastore_write:pass@postgres/datastore_test \
    CKAN_DATASTORE_READ_URL=postgresql://datastore_read:pass@postgres/datastore_test \
    CKAN_SOLR_URL=http://solr:8983/solr/ckan_registry \
    CKAN_REDIS_URL=redis://redis:6379/1

# Install system dependencies
RUN apk update && apk add jpeg-dev git \
    && pip install setuptools==44.1.0 \
    && pip install --upgrade pip==23.2.1 \
    && git clone https://github.com/open-data/ckan.git /srv/app/src/ckan \
    && cd /srv/app/src/ckan \
    && git checkout canada-py3 \
    && pip install -r requirements.txt -r dev-requirements.txt \
    && pip install -e .

# Clone and install necessary extensions
# ckanext-canada from our fork
RUN git clone https://github.com/gc-performance/ckanext-canada.git \ 
&& pip install -r ./ckanext-canada/requirements.txt \
&& pip install -e ./ckanext-canada

# ckanext-scheming
RUN git clone https://github.com/ckan/ckanext-scheming.git \
&& pip install -e ./ckanext-scheming

# ckanext-security
RUN git clone https://github.com/open-data/ckanext-security.git \ 
&& pip install -r ./ckanext-security/requirements.txt \
&& pip install -e ./ckanext-security

# ckanext-fluent
RUN git clone https://github.com/ckan/ckanext-fluent.git \
&& install -r ./ckanext-fluent/requirements.txt \
&& pip install -e ./ckanext-fluent

# ckanext-recombinant
RUN git clone https://github.com/open-data/ckanext-recombinant.git \
&& pip install -r ./ckanext-recombinant/requirements.txt \
&& pip install -e ./ckanext-recombinant

# ckanext-dcat
RUN git clone https://github.com/open-data/ckanext-dcat.git \
&& pip install -r ./ckanext-dcat/requirements.txt \
&& pip install -e ./ckanext-dcat

# Run CKAN setup
RUN python setup.py develop --user

# Generate CKAN config file
RUN ckan generate config ckan.ini

# Set up storage
RUN mkdir /workspace/data \
    && ckan config-tool ckan.ini "ckan.storage_path=/workspace/data"

# Set up site URL, assuming environment variables are set for CODESPACE_NAME and GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN
ARG CKAN_SITE_URL
RUN ckan config-tool ckan.ini "ckan.site_url=${CKAN_SITE_URL}"

# Initialize the database
RUN ckan db init

# Create sysadmin user
RUN ckan user add ckan_admin email=admin@example.com password=test1234 \
    && ckan sysadmin add ckan_admin

# Set up DataStore + DataPusher
RUN API_TOKEN=$(ckan user token add ckan_admin datapusher | tail -n 1 | tr -d '\t') \
    && ckan config-tool ckan.ini "ckan.datapusher.api_token=${API_TOKEN}" \
    && ckan config-tool ckan.ini \
        "ckan.datastore.write_url=postgresql://ckan_default:pass@localhost/datastore_default" \
        "ckan.datastore.read_url=postgresql://datastore_default:pass@localhost/datastore_default" \
        "ckan.datapusher.url=http://localhost:8800" \
        "ckan.datapusher.callback_url_base=http://localhost:5000" \
        "ckan.plugins=activity datastore datapusher datatables_view"

# Set permissions for DataStore
RUN ckan datastore set-permissions | psql $(grep ckan.datastore.write_url ckan.ini | awk -F= '{print $2}')

# Expose port 5000 for web interface
EXPOSE 5000

# Run CKAN
CMD ["ckan", "run", "--host", "0.0.0.0"]