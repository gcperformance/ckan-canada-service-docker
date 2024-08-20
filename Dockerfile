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
RUN pip install -e 'git+https://github.com/ckan/ckanext-fluent.git#egg=ckanext-fluent' -r 'https://raw.githubusercontent.com/ckan/ckanext-fluent/master/requirements.txt'
RUN pip install -e 'git+https://github.com/open-data/ckanext-recombinant.git#egg=ckanext-recombinant' -r 'https://raw.githubusercontent.com/open-data/ckanext-recombinant/master/requirements.txt'
RUN pip install -e 'git+https://github.com/ckan/ckanext-scheming.git#egg=ckanext-scheming'
RUN pip install -e 'git+https://github.com/open-data/ckanext-validation.git@canada-py3#egg=ckanext-validation' -r 'https://raw.githubusercontent.com/open-data/ckanext-validation/canada-py3/requirements.txt' -r 'https://raw.githubusercontent.com/open-data/ckanext-validation/canada-py3/dev-requirements.txt'
RUN pip install -e 'git+https://github.com/open-data/ckanext-xloader.git@canada-py3#egg=ckanext-xloader' -r 'https://raw.githubusercontent.com/open-data/ckanext-xloader/canada-py3/requirements.txt' -r 'https://raw.githubusercontent.com/open-data/ckanext-xloader/canada-py3/dev-requirements.txt'
RUN pip install -e 'git+https://github.com/ckan/ckantoolkit.git#egg=ckantoolkit' -r 'https://raw.githubusercontent.com/ckan/ckantoolkit/master/requirements.txt'
RUN pip install -e 'git+https://github.com/open-data/goodtables.git@canada-py3#egg=goodtables' -r 'https://raw.githubusercontent.com/open-data/goodtables/canada-py3/requirements.txt'
RUN pip install -e 'git+https://github.com/open-data/ckanext-security.git@canada-py3#egg=ckanext-security' -r 'https://raw.githubusercontent.com/open-data/ckanext-security/canada-py3/requirements.txt'
RUN find /srv/app/ -name '*.pyc' -delete

# Fetch and merge changes from pull request #1503
RUN git clone https://github.com/open-data/ckanext-canada.git /srv/app/src/ckanext-canada && \
    cd /srv/app/src/ckanext-canada && \
    git fetch origin pull/1503/head:PR1503 && \
    git checkout master && \
    git merge PR1503

# Install CKAN Canada extension
RUN pip install -e /srv/app/src/ckanext-canada/ -r 'https://raw.githubusercontent.com/open-data/ckanext-canada/master/requirements.txt' -r 'https://raw.githubusercontent.com/open-data/ckanext-canada/master/test-requirements.txt'

# CKAN setup
RUN rm ./ckan.ini ./who.ini

COPY . .
RUN ln -s /srv/app/src/ckan/who.ini ./links/who.ini
RUN mkdir -p ./links/

# copy work over
COPY service.yaml /srv/app/src/ckanext-canada/ckanext/canada/tables/service.yaml

## Expose port 5000 for web interface
EXPOSE 5000

#CMD ["start.sh"]
