#!/usr/local/bin/bash

DIA=`date +%Y-%m-%d-%H%M%S`
DIA_DEL=`date -v-7d +%Y-%m-%d`                 # Quantidade de dias que os arquivos serão guardados

# Retorna todos os databases existentes
DATABASES=`/usr/local/bin/psql --tuples-only -U pgsql postgres -c "select datname from pg_catalog.pg_database"`

for banco in $DATABASES; do
        /usr/local/bin/pg_dump -U pgsql --format=c $banco -f /d1/backup/dump/$banco-$DIA.pgdump
        if [ $? -gt 0 ] ; then
                echo "`date`: problema no backup do database $banco." >> erros.log
        fi
done


cd /d1/backup/dump

# Remove os arquivos de backup
rm -f *$DIA_DEL.pgdump
