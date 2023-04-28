#!/bin/bash

if [ -z "$2" ] ; then
    echo "usage: $0 image-name version-tag [domain-name]"
    echo example: $0 mattermost-team-edition 7.1.9-rc1
    echo example: $0 mattermost-team-edition 7.1.9-rc1 mm.foobar.com
    echo Valid values for image-name are likely:
    echo "  mattermost-team-edition"
    echo "  mattermost-enterprise-edition"
    exit
fi
edition=$1
version=$2
scheme=https
domain_name=$3
if [ -z "$domain_name" ] ; then
    domain_name=localhost
    scheme=http
fi


echo 'Need sudo to remove and create directories under ./docker'
sudo rm -rf docker
if [ ! -d "docker" ] ; then
    git clone https://github.com/mattermost/docker
    pushd docker
else
    pushd docker
    git pull
fi

cat >.env <<EOF
DOMAIN=$domain_name
TZ=UTC
RESTART_POLICY=unless-stopped
POSTGRES_IMAGE_TAG=13-alpine
POSTGRES_DATA_PATH=./volumes/db/var/lib/postgresql/data
POSTGRES_USER=mmuser
POSTGRES_PASSWORD=password
POSTGRES_DB=mattermost
NGINX_IMAGE_TAG=alpine
NGINX_CONFIG_PATH=./nginx/conf.d
NGINX_DHPARAMS_FILE=./nginx/dhparams4096.pem
CERT_PATH=./volumes/web/cert/cert.pem
KEY_PATH=./volumes/web/cert/key-no-password.pem
HTTPS_PORT=443
HTTP_PORT=80
CALLS_PORT=8443
MATTERMOST_CONFIG_PATH=./volumes/app/mattermost/config
MATTERMOST_DATA_PATH=./volumes/app/mattermost/data
MATTERMOST_LOGS_PATH=./volumes/app/mattermost/logs
MATTERMOST_PLUGINS_PATH=./volumes/app/mattermost/plugins
MATTERMOST_CLIENT_PLUGINS_PATH=./volumes/app/mattermost/client/plugins
MATTERMOST_BLEVE_INDEXES_PATH=./volumes/app/mattermost/bleve-indexes
MM_BLEVESETTINGS_INDEXDIR=/mattermost/bleve-indexes
MATTERMOST_IMAGE=$edition
MATTERMOST_IMAGE_TAG=$version
MATTERMOST_CONTAINER_READONLY=false
APP_PORT=8065
MM_SQLSETTINGS_DRIVERNAME=postgres
MM_SQLSETTINGS_DATASOURCE=postgres://mmuser:password@postgres:5432/mattermost?sslmode=disable&connect_timeout=10
MM_SERVICESETTINGS_SITEURL=$scheme://$domain_name
EOF

mkdir -p ./volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes}
sudo chown -R 2000:2000 ./volumes/app/mattermost

echo "OK to start $edition $version?"
read -p '[Y/n] > ' okp
if [ -z "$okp" ] || [ "$okp" == Y ] || [ "$okp" == y ] ; then
    docker-compose -f docker-compose.yml -f docker-compose.without-nginx.yml up
else
    exit
fi

echo "Remove containers?"
read -p '[Y/n] > ' okp
if [ -z "$okp" ] || [ "$okp" == Y ] || [ "$okp" == y ] ; then
    docker-compose -f docker-compose.yml -f docker-compose.without-nginx.yml rm
else
    exit
fi

