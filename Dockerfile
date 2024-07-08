# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        build-essential \
        libpq-dev \
        python3-dev \
        libxml2-dev \
        libxslt1-dev \
        libssl-dev \
        libmagic-dev \
        libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# Clone the open-data CKAN fork and switch to the specified branch
RUN git clone https://github.com/open-data/ckan.git

# Install CKAN
RUN pip install -r ./ckan/requirements.txt && pip install -r ./ckan/dev-requirements.txt
RUN pip install -e ./ckan
RUN pip install python-json-logger rdflib geomet future googleanalytics flask markupsafe 

# Clone and install necessary extensions
# ckanext-canada from our fork
RUN git clone https://github.com/gc-performance/ckanext-canada.git
RUN pip install -r ./ckanext-canada/requirements.txt
RUN pip install -e ./ckanext-canada

# ckanext-scheming
RUN git clone https://github.com/ckan/ckanext-scheming.git
RUN pip install -e ./ckanext-scheming

# ckanext-security
RUN git clone https://github.com/open-data/ckanext-security.git
RUN pip install -r ./ckanext-security/requirements.txt
RUN pip install -e ./ckanext-security

# ckanext-fluent
RUN git clone https://github.com/ckan/ckanext-fluent.git
RUN pip install -r ./ckanext-fluent/requirements.txt
RUN pip install -e ./ckanext-fluent

# ckanext-recombinant
RUN git clone https://github.com/open-data/ckanext-recombinant.git
RUN pip install -r ./ckanext-recombinant/requirements.txt
RUN pip install -e ./ckanext-recombinant

# ckanext-dcat
RUN git clone https://github.com/open-data/ckanext-dcat.git
RUN pip install -r ./ckanext-dcat/requirements.txt
RUN pip install -e ./ckanext-dcat

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