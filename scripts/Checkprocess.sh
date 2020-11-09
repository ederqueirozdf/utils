#!/bin/bash


# Version: 1.0
# Date of create: 06/11/2020
# Create by: Eder Queiroz
# Description: Script para analise de comportamento da porta 427

PORT="427"
ZBX=zabbix
KEYZBX=key.xyz

VERIFYPROCESS(){

declare -a LIST=( "srv204" "srv205" "srv206" "srv208" "srv210" "srv216" "srv301" "srv302" "srv303" "srv305" "srv306" "srv307" "srv308" "srv316" )
 for host in ${LIST[@]};
     do
        echo $host
        PROCESS=$(snmpwalk -v2c -c zbxmma $host | grep established | grep $PORT | cut -d"." -f3-7 | wc -l)
        if [ $PROCESS = 0 ];then
          zabbix_sender -z $ZBX -s $host -k $KEYZBX -o 0
        else
          zabbix_sender -z $ZBX -s $host -k $KEYZBX -o $PROCESS
        fi
    done
}

VERIFYPROCESS
