#!/bin/bash

url=localhost
dst=/tmp
backup=/backup/index.html
workdir=/var/www/html/
logs=/tmp/verifypage.log
DATA=date
MD5=c840bdc2afd22243cbeb4a56fad595b1
CLOCK=`date +%d-%m-%Y-%H:%M:%S`
ZBX=10.1.1.130
HOSTNAMEZBX=Mapas
KEYZBX=key.defacement


WGET (){

	echo -e "\n------------------------" >> $logs
	echo "RUN SCRIPT: $CLOCK"	       >> $logs
        echo -e "------------------------\n" >> $logs
	cd $dst
	wget $url
}


VALIDAHASH(){

	HASH=$(md5sum $dst/index.html | awk '{print $1}')
	if [ $HASH = $MD5 ];then
		echo "VALID"		>> $logs
	zabbix_sender -z $ZBX -s $HOSTNAMEZBX -k $KEYZBX -o 0
	else
		echo "INVALID"		>> $logs
	zabbix_sender -z $ZBX -s $HOSTNAMEZBX -k $KEYZBX -o 1
		RESTOREFILE
	fi
	echo -e "\n"			      >> $logs
	echo "------------------------------" >> $logs
	echo -e "\n"			      >> $logs
}

REMOVEFILE(){

	rm -rf $dst/index*
}

RESTOREFILE(){

	echo "Restore File ..."
	sleep 3
	cp -rf $backup $workdir
	REMOVEFILE
	WGET
}

WGET
VALIDAHASH
REMOVEFILE

