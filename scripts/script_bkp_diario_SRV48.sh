#Script de backup 
#!/usr/bin/bash

#Declaracao de variveis
DIR=/dados/postgresql/backup/dump/diario                         # diretorio de destino dos arquivos de backup
DIA=`date +%Y%m%d-%H%M%S`
LOG=/dados/postgresql/backup/dump/diario/LOG_backup-${DIA}.log   # diretorio de destino dos arquivos de log do backup
BIN=/usr/lib/postgresql/9.5/bin                                  # diretorio aonde se encontra os binarios do postgres
DIA_DEL=`date --date='7 days ago' +%Y%m%d`                        # Quantidade de dias que os arquivos serao guardados

echo "+----------------------------------------------------------------+"      >> $LOG
echo "| Rotina  : Backup Diario                                        |"      >> $LOG
echo "| Inicio  : "`date +%Y-%m-%d-%R:%S`"                                  |" >> $LOG
echo "| Em      : "`uname -n`                                                  >> $LOG
echo "+----------------------------------------------------------------+"      >> $LOG


echo ""                                        >> $LOG
echo "+-------------------------------------+" >> $LOG
echo "| Executa o Backup                    |" >> $LOG
echo "+-------------------------------------+" >> $LOG
echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG
echo ""                                        >> $LOG


# Retorna todos os databases existentes
DATABASES=`$BIN/psql -h 127.0.0.1 --tuples-only -U postgres postgres -c "select datname from pg_catalog.pg_database where datname not like 'template0'"`


# Realiza um loop nos bancos retornados e efetua o backup em todos
for banco in $DATABASES; do
        $BIN/pg_dump -h 127.0.0.1 -U postgres --format=p $banco -f $DIR/$banco-$DIA.dump
        if [ $? -gt 0 ] ; then
                echo "`date`: problema no backup do database $banco." >> $LOG
        fi
done


echo ""                                        >> $LOG
echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG

echo ""                                        >> $LOG
echo "+-------------------------------------+" >> $LOG
echo "| Compacta Backup                     |" >> $LOG
echo "+-------------------------------------+" >> $LOG
echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG
echo ""                                        >> $LOG

cd $DIR
echo " Compactando os arquivos de backup" >> $LOG
	tar -zcvf backup_pgsql-$DIA.tar.gz *.dump 2>> $LOG

echo ""                                        >> $LOG
echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG

echo ""                                        >> $LOG
echo "+-------------------------------------+" >> $LOG
echo "| Apaga arquivos antigos              |" >> $LOG
echo "+-------------------------------------+" >> $LOG
echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG
echo ""                                        >> $LOG
  
echo " Removendo os arquivos de backup" >> $LOG
	rm -f $DIR/*.dump

echo " Removendo os arquivos compactados do dia anterior" >> $LOG	
	rm -Rf $DIR/backup_pgsql-$DIA_DEL*.tar.gz
	
echo " Removendo os arquivos de log do dia anterior" >> $LOG	
	rm -Rf $DIR/LOG_backup-$DIA_DEL*.log

echo ""                                        >> $LOG
echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG	

echo ""                                                                        >> $LOG
echo "+----------------------------------------------------------------+"      >> $LOG
echo "| Rotina  : Backup Diario                                        |"      >> $LOG
echo "| Termino : "`date +%Y-%m-%d-%R:%S`"                                  |" >> $LOG
echo "| Log em  : $LOG"                                                        >> $LOG
echo "+----------------------------------------------------------------+"      >> $LOG
