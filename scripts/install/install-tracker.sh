#!/bin/bash
#
# Logstash server install
# @author Romain Ruaud
#
# Configuration stuffs
LOGSTASH_VERSION=2.1

if [ "$#" -lt 1 ]; then
    echo "Usage : ./install-tracker.sh TRACKER_LOG_FILE"
    echo "Eg. ./install-tracker.sh /var/log/smile_searchandising_suite/apache_raw_events/*.log"
    exit 1
fi

TRACKER_LOG_FILE=${1%/}

wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -

echo "deb http://packages.elastic.co/logstash/$LOGSTASH_VERSION/debian stable main" > /etc/apt/sources.list.d/logstash.list

apt-get update
apt-get install logstash

# Deploy Logstash configuration
cp -rfv logstash-configuration/es-template.json /etc/logstash/
sed -e "s/SMILE_ELASTICSUITE_TRACKER_TEMPLATE/\/etc\/logstash\/es-template.json/" logstash-configuration/injest-events-output.conf.sample > /etc/logstash/conf.d/injest-events-output.conf
sed -e "s~SMILE_TRACKER_LOG_FILE~$TRACKER_LOG_FILE~" logstash-configuration/injest-events-input.conf.sample > /etc/logstash/conf.d/injest-events-input.conf
cp -rfv logstash-configuration/injest-events-filter.conf.sample /etc/logstash/conf.d/injest-events-filter.conf

# Ensure corrects ACL for logstash on files
mkdir -p /var/log/smile_searchandising_suite/apache_raw_events/
setfacl -m u:logstash:r /var/log/apache2/*
setfacl -m u:logstash:r /var/log/smile_searchandising_suite/apache_raw_events/
setfacl -m u:logstash:r $TRACKER_LOG_FILE

# Start Logstash and ensure it starts with the system
service logstash restart
update-rc.d logstash defaults

echo ""
echo "Tracker installation finished."