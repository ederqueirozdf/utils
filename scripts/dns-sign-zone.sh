#!/bin/bash
# Script para criação de zona DNS
# Nov. 2017, Eder Queiroz
# Readme: Script para criação de chaves de zona de DNS e configuração de ZONA com DNSSEC. Validade de chaves para assinatura de zonas configuradas para 03 meses.

if [ -z "$1" ]
then
        echo "Usage: sign-zone.sh ZONE_NAME"
        exit 1
fi

ZONE=$1
ANO=$(date --date='3 months' |awk '{print $6}')
EXPIRATION=$(date --date="+3 months" +%m%d%H%M%S)
ROOT=/var/named
CONF=/var/named

update_serial() {
        DATENOW=$(date +%Y%m%d)
        SERIAL=$(head $ROOT/${ZONE}.zone.ext | grep -i serial | sed 's/[\ |\t]//g' | awk -F';' '{print $1}')
        SERIALDATE=$(echo $SERIAL | cut -b1-8)
        SERIALID=$(echo $SERIAL | cut -b9-10)

        if [ $SERIALDATE -lt $DATENOW ]; then
                sed -i -e 's/'$SERIALDATE''$SERIALID'/'$DATENOW'01/g' $ROOT/${ZONE}.zone.ext
        else
                sed -i -e 's/'$SERIAL'/'`((SERIAL++)) ; echo $SERIAL`'/g' $ROOT/${ZONE}.zone.ext
        fi
}

update_serial

cd $ROOT

/usr/sbin/dnssec-signzone -o $ZONE -e $ANO$EXPIRATION -k $CONF/ksk/K${ZONE}.*.key ${ZONE}.zone.ext $CONF/zsk/K${ZONE}.*.key
chown named:named $ROOT/*

exit 0

