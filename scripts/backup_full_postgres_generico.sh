#!/bin/bash

DIA=`date +%Y-%m-%d`
DIA_DEL=`date -d "2 day ago" +%Y-%m-%d`

# Retorna todos os databases existentes
DATABASES=`/usr/bin/psql --tuples-only -U postgres postgres -c "select datname from pg_catalog.pg_database where datname not in ('template0')"`


for banco in $DATABASES; do
        /usr/pgsql-9.6/bin/pg_dump -U postgres $banco -f /data/backup/dump/$banco-$DIA.sql
        if [ $? -gt 0 ] ; then
                echo "`date`: problema no backup do database $banco." >> erros.log
        fi
done

cd /data/backup/dump

# Remove os arquivos de backup
rm -f *$DIA_DEL.sql
