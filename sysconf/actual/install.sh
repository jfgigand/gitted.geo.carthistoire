# Installer script for sysconf "nef.service.carthistoire"  -*- shell-script -*-

. /usr/lib/sysconf.base/common.sh

_carthistoire_install()
{
    local _packages=""

    # HTTPd and PHP
    _packages="$_packages apache2-mpm-prefork libapache2-mod-php5"
    _packages="$_packages php5-cli"
    # _packages="$_packages php5-cli php-pear"

    # Databases
    _packages="$_packages postgresql-9.1 postgresql-9.1-postgis"
    # _packages="$_packages mongodb-server"

    # MapServer and GDAL
    # _packages="$_packages mapserver-bin cgi-mapserver php5-mapscript"
    # _packages="$_packages libgdal1 gdal-bin"

    # Misc
    # _packages="$_packages curl bzip2 unzip"
    # _packages="$_packages openjdk-7-jre-headless" # for shrinksafe JS builds

    # system
    _packages="$_packages rsyslog sudo git"
    #_packages="$_packages cron"

    _packages="$_packages libfcgi0ldbl"

    sysconf_require_packages $_packages

    if ! dpkg -l | grep -q tinyows; then
        dpkg -i tinyows_20110126-okapi-1_amd64.deb # FIXME: old package to upgrade
    fi

    # # Update /etc/mongodb.conf
    # _md5=$(md5sum /etc/mongodb.conf)
    # echo -e "# Generated by sysconf.app.carthistoire/install.sh on $(date)\n" >/etc/mongodb.conf
    # cat /etc/mongodb.conf.d/*.mongodb.conf >>/etc/mongodb.conf
    # [ "$_md5" != "$(md5sum /etc/mongodb.conf)" ] && {
    #     echo "/etc/mongodb.conf has changed. restarting MongoDB..."
    #     service mongodb restart
    #     # sleep 2
    # }

    local _pg_config=/etc/postgresql/9.1/main/postgresql.conf
    if [ -f $_pg_config ]; then
        rm -f $_pg_config
        echo "Setting symlink for: $_pg_config"
        ln -s ../../../postgresql-common/postgresql.conf $_pg_config
        service postgresql restart
    fi

    # # local _line="host all all 0.0.0.0/0 trust"
    # # local _pg_config_path=/etc/postgresql/9.1/main
    # # if ! grep -q "$_line" $_pg_config_path/pg_hba.conf; then
    # #     echo -e "# Added by sysconf.app.carthistoire/install.sh\n$_line" >>$_pg_config_path/pg_hba.conf
    # # fi

    # # setup MongoDB replica
    # if ! echo -e "use local\nshow collections" | mongo | grep -q oplog.rs; then
    #     echo "Activating the MongoDB replica..."
    #     # for i in 1 2 3 4 5; do netstat -tlpn | grep mongo; sleep 1; done
    #     echo -e "use local\nrs.initiate()" | mongo
    #     service mongodb restart
    #     sleep 2
    # fi

    # # Install custom packages
    # for url in \
    #     https://raw.githubusercontent.com/geonef/sysconf.nef.dirty/master/tree/var/lib/nef-cloud/packages/php5-mongo_20121217-okapi-1_amd64.deb \
    #     https://raw.githubusercontent.com/geonef/php5-gdal/master/builds/php5-gdal_20140613-1_amd64.deb \
    #     ; do

    #     package=$(basename "$url")
    #     regexp=$(echo $(basename $package .deb) | sed "s/_/ +/g")
    #     if ! dpkg -l | grep -qE "$regexp"; then
    #         # https://raw.githubusercontent.com/geonef/sysconf.nef.dirty/master/tree/var/lib/nef-cloud/packages/
    #         nef_log "installing package [$regexp]: $url"
    #         curl $url >/tmp/$package && dpkg -i /tmp/$package && rm -f /tmp/$package \
    #             || nef_fatal "could not download or extract package $package"
    #     fi
    # done
    # # Fix Php5-mongo
    # [ -f /etc/php5/conf.d/mongo.ini ] \
    #     || echo "extension=mongo.so" >/etc/php5/conf.d/mongo.ini

    # Clean-up after package install
    rm -f /etc/apache2/sites-enabled/000-default

    # # Install system-wide Swift 4.0.6 (PHP Mailer)
    # if ! pear list -c pear.swiftmailer.org | grep -q " 4.0.6 "; then
    #     pear channel-discover pear.swiftmailer.org
    #     pear install swift/Swift-4.0.6
    # fi

    # # Install OpenLayers 2.11rc3
    # [ -d /usr/share/javascript/openlayers-2.11rc3 ] || {
    #     mkdir -p /usr/share/javascript/openlayers-2.11rc3 || nef_fatal "could not mkdir"
    #     # OLD URL: url=http://openlayers.org/download/OpenLayers-2.11-rc3.tar.gz
    #     url=https://github.com/openlayers/openlayers/archive/release-2.11-rc3.tar.gz
    #     curl --location "$url" \
    #         | tar xzv --strip-components=1 -C /usr/share/javascript/openlayers-2.11rc3 \
    #         --exclude=doc --exclude=apidoc_config --exclude=examples \
    #         --exclude=doc_config --exclude=tests \
    #         || nef_fatal "could not download or extract OpenLayers archive from: $url"
    # }

    # # Install Proj4JS 1.0.1
    # [ -d /usr/share/javascript/proj4js-1.0.1 ] || {
    # cd /tmp
    # curl http://trac.osgeo.org/proj4js/raw-attachment/wiki/Download/proj4js-1.0.1.zip >proj4js-1.0.1.zip \
    #     && unzip proj4js-1.0.1.zip \
    #     && mv proj4js /usr/share/javascript/proj4js-1.0.1 \
    #     && rm -f /tmp/proj4js-1.0.1.zip \
    #     || nef_fatal "could not download or install proj4js"
    # }

    # # Install dojo-1.5.3-src
    # [ -d /usr/share/javascript/dojo-release-1.5.3-src ] || {
    #     cd /usr/share/javascript
    #     curl http://download.dojotoolkit.org/release-1.5.3/dojo-release-1.5.3-src.tar.gz \
    #         | tar xzv --no-same-owner --exclude=tests --exclude=demos --exclude=docscripts --exclude=doh \
    #         || nef_fatal "could not download or extract the dojo-release-1.5.3-src archive"
    # }
}

_carthistoire_setup()
{
    # # "carthistoire" UNIX account
    # grep -q ^carthistoire: /etc/passwd || {
    #     useradd -d / -G www-data carthistoire
    # }

    local rootdir=/var/lib/carthistoire
    if [ ! -h $rootdir/app/instance ]; then
        ln -s instances/prod $rootdir/app/instance
    fi

    if [ $(stat -c %U $rootdir/app/cache) != www-data ]; then
        echo CHOWNNNNNNNN
        chown -R www-data:www-data $rootdir/app/{cache,logs}
    fi
    # sudo -u www-data $rootdir

    # "carthistoire" PostgreSQL account
    if ! echo '\dg' | sudo -u postgres psql | grep -q carthistoire; then
        echo "CREATE ROLE carthistoire PASSWORD 'NNrPLvp1aAhsWvLGpdpQ1xFjDAv2iTHT' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;" | sudo -u postgres psql
    fi

    # Apache setup
    # Fix the error: /usr/sbin/apachectl: 87: ulimit: error setting limit (Operation not permitted)
    if ! grep -q ^APACHE_ULIMIT_MAX_FILES= /etc/apache2/envvars; then
        cat >>/etc/apache2/envvars <<EOF

# Added by sysconf.app.carthistoire:
APACHE_ULIMIT_MAX_FILES=false
EOF
    fi
    # Fix the error: apache2: Could not reliably determine the server's fully qualified domain name, using x.x.x.x for ServerName
    if [ ! -f /etc/apache2/conf.d/server-name ]; then
        cat >/etc/apache2/conf.d/server-name <<EOF

# Added by sysconf.app.carthistoire:
ServerName $(hostname)
EOF
    fi
    _carthistoire_enable_apache_module headers.load
    _carthistoire_enable_apache_module rewrite.load
    _carthistoire_enable_apache_module expires.load
}

_carthistoire_enable_apache_module()
{
    moduleName=$1
    [ -h /etc/apache2/mods-enabled/$moduleName ] || \
        ln -s ../mods-available/$moduleName /etc/apache2/mods-enabled/
}

_carthistoire_reload()
{
    if apachectl -S >/dev/null 2>&1; then
        apachectl graceful
    else
        echo "Not restarting Apache2, please execute `apachectl -S` for more info."
    fi
}

_carthistoire_install
_carthistoire_setup
_carthistoire_reload

#update-rc.d mapserver defaults
#service mapserver start