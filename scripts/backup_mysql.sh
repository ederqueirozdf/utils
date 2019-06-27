#Script de backup 
#!/usr/local/bin/bash

#Declaracao de variveis
DIR=/vol2/backup/mysql                         # diretorio de destino dos arquivos de backup
DIA=`date +%Y-%m-%d-%H%M%S`
LOG=/vol2/backup/mysql/LOG_backup-${DIA}.log   # diretorio de destino dos arquivos de log do backup
BIN=/usr/local/bin                             # diretorio aonde se encontra os binarios do mysql
DIA_DEL=`date -v-7d +%Y-%m-%d`                 # Quantidade de dias que os arquivos serão guardados
MYUSER=backup
PASS=backup

# Retorna todos os databases existentes
DATABASES=`$BIN/mysql --user=$MYUSER --password=$PASS --execute='show databases'`

echo "+----------------------------------------------------------------+"      >> $LOG
echo "| Rotina  : Backup Noturno                                       |"      >> $LOG
echo "| Inicio  : "`date +%Y-%m-%d-%R:%S`"                                  |" >> $LOG
echo "| Em      : "`uname -n`                                                  >> $LOG
echo "+----------------------------------------------------------------+"      >> $LOG


echo ""                                        >> $LOG
echo "+-------------------------------------+" >> $LOG
echo "| Executa o Backup                    |" >> $LOG
echo "+-------------------------------------+" >> $LOG
echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG
echo ""                                        >> $LOG

# Realiza um loop nos bancos retornados e efetua o backup em todos

for banco in $DATABASES; do
	if [ $banco != 'Database' ]
	then
		if $BIN/mysqldump --user=$MYUSER --password=$PASS --databases $banco > $DIR/$banco.sql
			then echo " backup efetuado com sucesso: " $banco >> $LOG
		else echo " Problema na execucao do backup: " $banco >> $LOG
		fi
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
	tar -zcvf backup_mysql-$DIA.tar.gz *.sql 2>> $LOG

echo ""                                        >> $LOG
echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG

echo ""                                        >> $LOG
echo "+-------------------------------------+" >> $LOG
echo "| Apaga arquivos antigos              |" >> $LOG
echo "+-------------------------------------+" >> $LOG
echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG
echo ""                                        >> $LOG
  
echo " Removendo os arquivos de backup" >> $LOG
	rm -f /$DIR/*.sql

echo " Removendo os arquivos compactados com mais de 1 mes" >> $LOG	
	rm -Rf /$DIR/backup_mysql-$DIA_DEL*.tar.gz
	
echo " Removendo os arquivos de log com mais de 1 mes" >> $LOG	
	rm -Rf /$DIR/LOG_backup-$DIA_DEL*.log

echo ""                                        >> $LOG
echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG	

echo ""                                                                        >> $LOG
echo "+----------------------------------------------------------------+"      >> $LOG
echo "| Rotina  : Backup Noturno                                       |"      >> $LOG
echo "| Termino : "`date +%Y-%m-%d-%R:%S`"                                  |" >> $LOG
echo "| Log em  : $LOG"                                                        >> $LOG
echo "+----------------------------------------------------------------+"      >> $LOG