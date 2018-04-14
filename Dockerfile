FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y -q apt-utils && apt-get install -y -q locales && dpkg-reconfigure locales && \
      locale-gen en_US.UTF-8 && \
      update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get -y update
RUN apt-get upgrade  -y --fix-missing


RUN useradd -m -d /home/cartodb -s /bin/bash cartodb && \
	apt-get install -y -q \
	build-essential \
    autoconf \
    automake \
    libtool \
    checkinstall \
    unp \
    zip \
    unzip \
    git-core \
    git \
    subversion \
    curl \
    libgeos-c1v5 \
    libgeos-dev \
    libjson0 \
    python-simplejson \
    libjson0-dev \
    proj-bin \
    proj-data \
    libproj-dev \
    gdal-bin \
    libgdal1-dev \
    libgdal-dev \
    postgresql-9.5 \
    postgresql-client-9.5 \
    postgresql-contrib-9.5 \
    postgresql-server-dev-9.5 \
    postgresql-plpython-9.5 \
    postgresql-9.5-plproxy \
    postgresql-9.5-postgis-2.2 \
    postgresql-9.5-postgis-scripts \
    postgis \
    liblwgeom-2.2-5 \
    ca-certificates \
    redis-server \
    python2.7-dev \
    python-setuptools \
    imagemagick \
    libmapnik-dev \
    mapnik-utils \
    python-mapnik \
    python-argparse \
    python-gdal \
    python-chardet \
    python-pip \
    python-all-dev \
    python-docutils \
    openssl \
    libreadline6 \
    zlib1g \
    zlib1g-dev \
    libssl-dev \
    libyaml-dev \
    libsqlite3-dev \
    sqlite3 \
    libxml2-dev \
    libxslt-dev \
    libc6-dev \
    ncurses-dev \
    bison \
    pkg-config \
    libpq5 \
    libpq-dev \
    libcurl4-gnutls-dev \
    libffi-dev \
    libgdbm-dev \
    gnupg \
    libreadline6-dev \
    libcairo2-dev \
    libjpeg8-dev \
    libpango1.0-dev \
    libgif-dev \
    libgmp-dev \
    libicu-dev \
    wget \
    nginx-light \
    net-tools \
  --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*
  
  
  RUN cd /opt && \
    wget http://varnish-cache.org/_downloads/varnish-3.0.7.tgz && \
    tar -zxf varnish-3.0.7.tgz && \
    cd varnish-3.0.7 && \
    ./configure --prefix=/opt/varnish && \
    make && \
    make install && \
    cd /opt && \
    rm -rf varnish-3.0.7 varnish-3.0.7.tgz

RUN apt-get -y update
RUN apt-get install -y software-properties-common python-software-properties
RUN add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable
RUN apt -y update 
RUN apt -y upgrade
# ogr2ogr2 static build, see https://github.com/CartoDB/cartodb/wiki/How-to-build-gdal-and-ogr2ogr2
# using cartodb instruction got error https://trac.osgeo.org/gdal/ticket/6073
# https://github.com/OSGeo/gdal/compare/trunk...CartoDB:ogr2ogr2 has no code changes, so just use latest gdal tarball
#RUN cd /opt && \
 #   curl http://download.osgeo.org/gdal/2.1.1/gdal-2.1.1.tar.gz -o gdal-2.1.1.tar.gz && \
  #  tar -zxf gdal-2.1.1.tar.gz && \
   # cd gdal-2.1.1 && \
    #./configure --disable-shared && \
    #make -j 4 && \
    #cp apps/ogr2ogr /usr/bin/ogr2ogr2 && \
    #cd /opt && \
  	#rm -rf /opt/ogr2ogr2 /opt/gdal-2.1.1.tar.gz /root/.gitconfig /opt/gdal-2.1.1

# Install NodeJS
RUN curl https://nodejs.org/download/release/v6.9.2/node-v6.9.2-linux-x64.tar.gz| tar -zxf - --strip-components=1 -C /usr && \
  npm install -g grunt-cli && \
  npm install -g npm@3.10.9 && \
  rm -r /tmp/npm-* /root/.npm

# Install rvm
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import -
ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E084DAB9 && \
    curl  https://raw.githubusercontent.com/wayneeseguin/rvm/stable/binscripts/rvm-installer | bash -s stable --ruby && \
    echo 'source /usr/local/rvm/scripts/rvm' >> /etc/bash.bashrc && \
    /bin/bash -l -c rvm requirements && \
    echo rvm_max_time_flag=15 >> ~/.rvmrc && \
    /bin/bash -l -c 'rvm install 2.2.3' && \
    /bin/bash -l -c 'rvm use 2.2.3 --default' && \
    /bin/bash -l -c 'gem install bundle archive-tar-minitar' && \
    /bin/bash -l -c 'gem install bundler compass --no-doc --no-ri' && \
    ln -s /usr/local/rvm/rubies/ruby-2.2.3/bin/ruby /usr/bin && \
    rm -rf /usr/local/rvm/src

# Setting PostgreSQL
RUN sed -i 's/\(peer\|md5\)/trust/' /etc/postgresql/9.5/main/pg_hba.conf && \
    service postgresql start && \
    createuser publicuser --no-createrole --no-createdb --no-superuser -U postgres && \
    createuser tileuser --no-createrole --no-createdb --no-superuser -U postgres && \
    service postgresql stop

# Crankshaft: CARTO Spatial Analysis extension for PostgreSQL
RUN cd / && \
    git clone https://github.com/CartoDB/crankshaft.git && \
    cd /crankshaft && \
    git checkout master && \
    make install && \
    cd ..

# Initialize template postgis db
ADD ./config/template_postgis.sh /tmp/template_postgis.sh
RUN service postgresql start && /bin/su postgres -c \
      /tmp/template_postgis.sh && service postgresql stop


#With git:// connection fails hence connecting other urls
RUN git config --global url.http://github.com/.insteadOf git://github.com/

# Install CartoDB API
RUN git clone -b "1.48.1" git://github.com/CartoDB/CartoDB-SQL-API.git && \
    cd CartoDB-SQL-API && \
    npm install && \
    rm -r /tmp/npm-* /root/.npm

# Install Windshaft
RUN git clone git://github.com/CartoDB/Windshaft-cartodb.git && \
    cd Windshaft-cartodb && \
    git checkout master && \
    npm install -g yarn@0.27.5 && \
    yarn install && \
    rm -r /tmp/npm-* /root/.npm && \
    mkdir logs
    
ADD ./config/cartodb_pgsql.sh /tmp/cartodb_pgsql.sh

# Install CartoDB
#Carto Editor
RUN git clone  -b "v4.11.82" --recursive http://github.com/CartoDB/cartodb.git &&\
cd cartodb &&\
wget  -O /tmp/get-pip.py http://bootstrap.pypa.io/get-pip.py &&\
python /tmp/get-pip.py 

RUN apt-get install -q -y python-all-dev &&\
apt-get install -q -y imagemagick unp zip 

RUN apt-get -q -y install rubygems
#RUN  bundle config build.charlock_holmes --with-icu-dir=/usr/local/opt/icu4c --with-cxxflags=\'-Wno-reserved-user-defined-literal -std=c++11\'

#RUN apt-get -q -y install libicu-dev   
#RUN gem install charlock_holmes -v '0.7.5'

#RUN gem install charlock_holmes -v '0.7.5'

RUN cd cartodb &&\
 cd lib/sql && \
    PGUSER=postgres make install && \
    service postgresql start && /bin/su postgres -c \
      /tmp/cartodb_pgsql.sh && service postgresql stop && \
    cd - && \
/bin/bash -l -c 'bundle install' &&\
/bin/bash -l -c 'npm install'



# Geocoder SQL client + server
RUN git clone https://github.com/CartoDB/data-services.git && \
  cd /data-services/geocoder/extension && PGUSER=postgres make all install && cd / && \
  git clone https://github.com/CartoDB/dataservices-api.git && \
  cd /dataservices-api/server/extension && \
  PGUSER=postgres make install && \
  cd ../lib/python/cartodb_services && \
  pip install -r requirements.txt && pip install . && \
  cd ../../../../client && PGUSER=postgres make install

# Observertory extension
RUN cd / && git clone --recursive git://github.com/CartoDB/observatory-extension.git && \
  cd observatory-extension && \
  PGUSER=postgres make deploy

ADD ./config/SQLAPI-dev.js \
     /CartoDB-SQL-API/config/environments/development.js
ADD ./config/WS-dev.js \
      /Windshaft-cartodb/config/environments/development.js
ADD ./config/app_config.yml /cartodb/config/app_config.yml
ADD ./config/database.yml /cartodb/config/database.yml

ADD ./config/grunt_development.json /cartodb/config/grunt_development.json



RUN service postgresql start && service redis-server start &&\
    cd /cartodb &&\
    /bin/bash -l -c 'bundle install' && \
     /bin/bash -l -c 'bundle exec rake db:create' &&\
     /bin/bash -l -c 'bundle exec rake db:migrate' &&\
     /bin/bash -l -c 'bundle exec rake cartodb:sync_tables[true]' &&\
     /bin/bash -l -c 'bundle exec rake cartodb:features:add_feature_flag['carto-connectors']' &&\
     /bin/bash -l -c 'bundle exec rake cartodb:features:enable_feature_for_all_users['carto-connectors']' &&\
     /bin/bash -l -c 'bundle exec rake cartodb:connectors:create_providers'  &&\
     service postgresql stop && service redis-server stop

RUN export SUBDOMAIN=development
ADD ./create_user.sh /cartodb/script/create_user.sh
RUN service postgresql start && service redis-server start && \
	bash -l -c "cd /cartodb && bash script/create_user.sh" && \
	service postgresql stop && service redis-server stop

RUN mkdir -p /cartodb/log && touch /cartodb/log/users_modifications 


ADD ./config/geocoder.sh /cartodb/script/geocoder.sh
ADD ./config/geocoder_server.sql /cartodb/script/geocoder_server.sql
ADD ./config/fill_geocoder.sh /cartodb/script/fill_geocoder.sh

RUN mkdir -p /cartodb/log && touch /cartodb/log/users_modifications && \
 service postgresql start && service redis-server start && \
	bash -l -c "cd /cartodb && bash script/geocoder.sh" && \
	service postgresql stop && service redis-server stop && \
    chmod +x /cartodb/script/fill_geocoder.sh 
   
ADD ./config/app_config.yml /cartodb/config/app_config.yml


EXPOSE 3000 8080 8181

#RUN export SUBDOMAIN=development

ENV GDAL_DATA /usr/share/gdal/2.2

# Number of seconds between a sync tables task is run
# Default interval is an hour, use `docker run -e SYNC_TABLES_INTERVAL=60 ...` to change it
ENV SYNC_TABLES_INTERVAL 3600

ADD ./startup.sh /opt/startup.sh

CMD ["/bin/bash", "/opt/startup.sh"]
HEALTHCHECK CMD curl -f http://localhost || exit 1

