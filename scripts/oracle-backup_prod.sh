#!/bin/bash
#==============================================================================#
#    Arquivo : oracle-backup.sh                                                #
#    Uso     : Script para backup de banco de dados Oracle                     #
#==============================================================================#
#    Funcoes do Script                                                         #
#                                                                              #
#  verifica_backup_path()                                                      #
#           - Cria a estrutura de path para execucao dos backups               #
#  verifica_discos()                                                           #
#           - Verifica se alguma das particicoes montadas esta com mais de 80% #
#             de ocupacao, utiliza o comando 'df'                              #
#  verifica_site_on_line()                                                     #
#           - Verifica se a instancia (ORACLE_SID) informada esta on-line,     #
#             utiliza o comando 'ps'                                           #
#  verifica_data_files()                                                       #
#           - Verifica a integridade dos arquivos fisicos de dados, utiliza o  #
#             utilitario 'dbv'                                                 #
#  verifica_alert()                                                            #
#           - Lista os erros 'ORA-' e 'SP2-' encontrados no alert              #
#  verifica_tablespaces()                                                      #
#           - Lista ocupacao das tablespaces                                   #
#  mostra_espaco_discos()                                                      #
#           - Lista espaco nos discos                                          #
#  define_mes_anterior()                                                       #
#           - Calcula o mes anterior ao mes corrente                           #
#  db_shutdown()                                                               #
#           - Executa um shutdown na instancia informada                       #
#             Faz um 'shutdown abort' -> 'startup' -> 'shutdown immediate'     #
#  db_startup()                                                                #
#           - Executa um startup na instancia informada                        #
#  db_analyze()                                                                #
#           - Executa um analyze em toda a instancia informada                 #
#  backup_logico_pump()                                                        #
#           - Executa um backup logico de toda a instancia informada com o     #
#             utilitario 'expdp' (data pump)                                   #
#  backup_logico_pump_schemas()                                                #
#           - Executa um backup logico dos schemas da instancia informada com  #
#             o utilitario 'expdp' (data pump)                                 #
#  backup_logico_export()                                                      #
#           - Executa um backup logico de toda a instancia informada com o     #
#             utilitario 'exp' (export)                                        #
#  backup_logico_export_schemas()                                              #
#           - Executa um backup logico dos schemas da instancia informada com  #
#             o utilitario 'exp' (export)                                      #
#  backup_fisico_check_archiving()                                             #
#           - Faz uma verificacao na instancia informada e verifica se a mesma #
#             esta em modo de 'ARCHIVELOG', caso nao esteja, coloca-a          #
#  backup_fisico_online()                                                      #
#           - Executa um backup fisico da instancia informada no modo on-line  #
#  backup_fisico_offline()                                                     #
#           - Executa um backup fisico da instancia informada no modo off-line #
#  backup_fisico_compara_arquivos()                                            #
#           - Faz uma verificacao dos arquivos copiados utilizando o comando   #
#             'du'                                                             #
#  backup_control_file()                                                       #
#           - Faz um backup dos control files da instancia informada           #
#             ALTER DATABASE BACKUP CONTROLFILE TO TRACE                       #
#  backup_spfile()                                                             #
#           - Faz um backup do 'spfile' em 'pfile'                             #
#  backup_move_archives()                                                      #
#           - Move todos os 'archives' da instancia informada para a area de   #
#             backup                                                           #
#  backup_move_trace()                                                         #
#           - Move todos os arquivos de trace (.trc) e de auditoria (.aud)     #
#             para a area de backup                                            #
#  compacta_backup_noturno()                                                   #
#           - Compacta todo o backup feito pela rotina de backup noturno       #
#==============================================================================#

#
# Validacao dos parametros de entrada
#
ORACLE_SID=$1
operation=$2

if [ -z $operation ]; then
   echo "***** Favor definir a operacao a ser executada"
   echo "***** chamada $0 $* ilegal"
   echo "***** uso: $0 "
   exit 2
fi

if [ -z $ORACLE_SID ]; then
   echo "***** Favor definir o nome do banco de dados"
   echo "***** chamada $0 $* ilegal"
   echo "***** uso: $0 "
   exit 2
fi

#
# Definicao das variaveis de ambiente
# (variaveis referenciadas fora do script precisam ser exportadas)
#
export ORACLE_SID
export ORACLE_BASE=/u01/oracle
export ORACLE_HOME=${ORACLE_BASE}/product/10g
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib
export NLS_LANG=AMERICAN_AMERICA.WE8ISO8859P1
export PATH=$PATH:${ORACLE_HOME}/bin
export PATHSQL=${ORACLE_BASE}/etc/sql
export PATHSCR=${ORACLE_BASE}/etc/script
export PATHBKP=/u05/oracle/backup/${ORACLE_SID}
#      export PATHARC=${ORACLE_BASE}/flash_recovery_area/${ORACLE_SID}/archivelog
export PATHARC=${ORACLE_BASE}/oradata/${ORACLE_SID}/archive
export EXECSQL=${PATHBKP}/sql
export DIA=`date +%Y-%m-%d-%H%M%S`
export LOG=${PATHBKP}/${operation}-${DIA}.log
export LOGPUP=${PATHBKP}/${operation}-${DIA}-pup
export LOGEXP=${PATHBKP}/${operation}-${DIA}-exp
export DEST_REMOTO=seu_servidor_remoto_de_backup

orausr=system
orapwd=bridas

dados=(/u01/oracle/oradata /u02/oracle/oradata /u03/oracle/oradata /u04/oracle/oradata)
oracle_mail=thiago.santos@globalweb.com.br

#
# Verifica Paths para backup
#
verifica_backup_path() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Verificando Path para Backup        |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  if [[ ! -d ${PATHBKP}/archive ]]; then
     mkdir -p ${PATHBKP}/archive
  fi

  if [[ ! -d ${PATHBKP}/export ]]; then
     mkdir -p ${PATHBKP}/export
  fi

  if [[ ! -d ${PATHBKP}/sql ]]; then
     mkdir -p ${PATHBKP}/sql
  fi

  if [[ ! -d ${PATHBKP}/datafiles ]]; then
     mkdir -p ${PATHBKP}/datafiles
  fi

  if [[ ! -d ${PATHBKP}/controlfile ]]; then
     mkdir -p ${PATHBKP}/controlfile
  fi

  if [[ ! -d ${PATHBKP}/adump ]]; then
     mkdir -p ${PATHBKP}/adump
  fi

  if [[ ! -d ${PATHBKP}/bdump ]]; then
     mkdir -p ${PATHBKP}/bdump
  fi

  if [[ ! -d ${PATHBKP}/cdump ]]; then
     mkdir -p ${PATHBKP}/cdump
  fi

  if [[ ! -d ${PATHBKP}/dpdump ]]; then
     mkdir -p ${PATHBKP}/dpdump
  fi

  if [[ ! -d ${PATHBKP}/udump ]]; then
     mkdir -p ${PATHBKP}/udump
  fi

  if [[ ! -d ${PATHBKP}/dbs ]]; then
     mkdir -p ${PATHBKP}/dbs
  fi

  if [[ ! -d ${PATHBKP}/compress ]]; then
     mkdir -p ${PATHBKP}/compress
  fi

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Verifica se alguma particao montada tem mais de 80% e 95% de ocupacao
#
verifica_discos() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Verificando ocupacao das particoes  |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  for part in `df -hlP -t ext3 | cut -c0-9`; do
      df $part > /dev/null 2> /dev/null
      if [ $? -eq 0 ]; then
         mount=`df $part | tail -l | awk '{print $6}'`
         percent=`df $part | tail -l | awk '{print $5}'`
         usep=$(echo $percent | awk '{print $2}' | cut -d'%' -f1)
         if [ $usep -gt 80 ] && [ $usep -lt 95 ]; then
            echo "Atencao: `uname -n` com $part montada em $mount esta com $percent ocupado." >> $LOG
            cat $LOG | mail -s "Alerta de disco em `uname -n`!" $oracle_mail
         elif [ $usep -ge 95 ]; then
            echo "ATENCAO URGENTE: `uname -n` com $part montada em $mount esta com $percent ocupado." >> $LOG
            cat $LOG | mail -s "ALERTA CRITICO DE DISCO em `uname -n`!" $oracle_mail
         fi
      fi
  done

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Verifica se site esta on-line
#
verifica_site_on_line() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Verificando se site esta on-line    |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  ok="On-Line"
  processo="`ps -ef | grep smon | grep -v grep | awk '{print $8}' | awk -F \"_\" '{print $3}'`"
  if [ "$processo" != "$ORACLE_SID" ]; then
     ok="Off-Line"
     echo "  Site    : $ORACLE_SID esta $ok"     >> $LOG
     echo "  Termino : "`date +%Y-%m-%d-%R:%S`   >> $LOG
     cat $LOG | mail -s "SITE: $ORACLE_SID em `uname -n` esta $ok" $oracle_mail
     exit 2
  fi

  echo "  Site    : $ORACLE_SID esta $ok"        >> $LOG
  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Faz uma verificacao nos arquivos fisicos do banco de dados
#
verifica_data_files() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Verificando datafiles               |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  sqlplus -s "/ as sysdba" <<-EOF_VERIFICA_DATA_FILES
  SET     FEEDBACK  OFF
  SET     TRIMSPOOL ON
  SET     TERMOUT   OFF
  SET     PAGES     0
  SET     PAGESIZE  0
  SET     LINES     250
  SET     LINESIZE  500
  SPOOL   ${EXECSQL}/${operation}_db_verify_data_files.out
    SELECT '!dbv file=' || file_name || ' >> ${PATHBKP}/${operation}-${DIA}-db-verify-data-files.log' ||
           ' 2>> ${PATHBKP}/${operation}-${DIA}-db-verify-data-files.log'
      FROM dba_data_files
  ORDER BY tablespace_name
         , file_name;
  SPOOL   OFF
  @${EXECSQL}/${operation}_db_verify_data_files.out
  EXIT
EOF_VERIFICA_DATA_FILES
  egrep --color -n -B 7 -A 9 'Total Pages Failing.*(Data).*[^0]$'  ${PATHBKP}/${operation}-${DIA}-db-verify-data-files.log \
        >> $LOG 2>> $LOG
  egrep --color -n -B 9 -A 7 'Total Pages Failing.*(Index).*[^0]$' ${PATHBKP}/${operation}-${DIA}-db-verify-data-files.log \
        >> $LOG 2>> $LOG
  egrep --color -n -B 9 -A 7 'Total Pages Marked Corrupt.*[^0]$'   ${PATHBKP}/${operation}-${DIA}-db-verify-data-files.log \
        >> $LOG 2>> $LOG

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Faz uma verificacao se existem erros no alert
#
verifica_alert() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Verificando erros no alert          |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  egrep --color -n -B 2 '(ORA-|SP2-)' \
        ${ORACLE_BASE}/admin/${ORACLE_SID}/bdump/alert_${ORACLE_SID}.log \
        >> ${PATHBKP}/${operation}-${DIA}-db-verify-alert.log 2>> $LOG

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Faz uma verificacao na ocupacao das tablespaces
#
verifica_tablespaces() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Verificando tablespaces             |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  sqlplus -s "/ as sysdba" <<-EOF_VERIFICA_TABLESPACES
  SET     FEEDBACK  OFF
  SET     TRIMSPOOL ON
  SET     TERMOUT   OFF
  SET     PAGES     0
  SET     PAGESIZE  0
  SET     LINES     250
  SET     LINESIZE  500
  SPOOL   ${EXECSQL}/${operation}_db_verify_tablespaces.log
    SELECT u.tablespace_name || ' com ' ||
           TO_CHAR(((100 * u.utilizado) / m.maximo), '999.9') || '% ocupado' tablespace
      FROM (  SELECT tablespace_name
                   , SUM(bytes) utilizado
                FROM dba_segments
            GROUP BY tablespace_name
           ) u
         , (  SELECT tablespace_name
                   , SUM(bytes) alocado
                   , SUM(DECODE(autoextensible, 'NO', bytes, maxbytes)) maximo
                FROM dba_data_files
            GROUP BY tablespace_name
           ) m
         , (  SELECT tablespace_name
                   , SUM(bytes) livre
                FROM dba_free_space
            GROUP BY tablespace_name
           ) l
     WHERE l.tablespace_name = u.tablespace_name
       AND l.tablespace_name = m.tablespace_name
       AND ((100 * u.utilizado) / m.maximo) > 80
    UNION
    SELECT tablespace_name || ' com ' ||
           TO_CHAR((100 * SUM(bytes)) / SUM(DECODE(autoextensible, 'NO', bytes, maxbytes)), '999.9') ||
           '% ocupado' tablespace
      FROM dba_temp_files
  GROUP BY tablespace_name
    HAVING ((100 * SUM(user_bytes)) / SUM(DECODE(autoextensible, 'NO', bytes, maxbytes))) > 80 ;
  SPOOL   OFF
  EXIT
EOF_VERIFICA_TABLESPACES
  cat ${EXECSQL}/${operation}_db_verify_tablespaces.log >> $LOG 2>> $LOG

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Mostra espaco em disco
#
mostra_espaco_discos() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Exibindo espaco em disco            |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  #df -hl -t ext3                                 >> $LOG 2>> $LOG
   df -hl                                         >> $LOG 2>> $LOG

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Define qual e o mes anterior
#
define_mes_anterior() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Define qual e o mes anterior        |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  mes=`date +%m`
  mes=$(expr $mes - 1)
  if [ $mes = 0 ]; then
     ano=`date +%Y`
     ano=$(expr $ano - 1)
     mes=${ano} - 12
  else
     mes=`date +%Y`-$mes
  fi

  echo "  Mes.Ant : "$mes                        >> $LOG
  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Para o banco de dados
#
db_shutdown() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Database Shutdown                   |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  # So pode ser executado pelo usuario Oracle do SO
  if [ $USER != 'oracle' ]; then
     echo "***** A operacao de shutdown nao e valida com o usuario $USER" >> $LOG
     echo "***** tente novamente com o usuario oracle do SO."             >> $LOG
     exit 2
  fi
  sqlplus -s "/ as sysdba" <<-EOF_DB_SHUTDOWN
  SET     FEEDBACK  OFF
  SET     TRIMSPOOL ON
  SET     TERMOUT   OFF
  SET     PAGES     0
  SET     PAGESIZE  0
  SET     LINES     250
  SET     LINESIZE  500
  SPOOL   ${EXECSQL}/${operation}_db_shutdown.log
  SHUTDOWN ABORT
  STARTUP
  SHUTDOWN IMMEDIATE
  SPOOL   OFF
  EXIT
EOF_DB_SHUTDOWN
  grep --color -n -B 2 ORA- ${EXECSQL}/${operation}_db_shutdown.log >>$LOG 2>> $LOG
  processo="`ps -ef | grep smon | grep -v grep | awk '{print $8}' | awk -F \"_\" '{print $3}'`"
  if [ "$processo" = "$ORACLE_SID" ]; then
     echo "***** Problema ao parar a instancia ${ORACLE_SID}"     >> $LOG
     echo "***** O servidor pode estar num estado inconsistente." >> $LOG
     cat $LOG | mail -s "URGENTE!!!  Erro ao para a instancia ${ORACLE_SID} em `uname -n`" $oracle_mail
     exit 2
  fi

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Inicia o banco de dados
#
db_startup() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Database Startup                    |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  # So pode ser executado pelo usuario Oracle do SO
  if [ $USER != 'oracle' ]; then
     echo "***** A operacao de startup nao e valida com o usuario $USER" >> $LOG
     echo "***** tente novamente com o usuario oracle do SO."            >> $LOG
     exit 2
  fi
  sqlplus -s "/ as sysdba" <<-EOF_DB_STARTUP
  SET     FEEDBACK  OFF
  SET     TRIMSPOOL ON
  SET     TERMOUT   OFF
  SET     PAGES     0
  SET     PAGESIZE  0
  SET     LINES     250
  SET     LINESIZE  500
  SPOOL   ${EXECSQL}/${operation}_db_startup.log
  STARTUP
  SPOOL   OFF
  EXIT
EOF_DB_STARTUP
  grep --color -n -B 2 ORA- ${EXECSQL}/${operation}_db_startup.log >>$LOG 2>> $LOG
  processo="`ps -ef | grep smon | grep -v grep | awk '{print $8}' | awk -F \"_\" '{print $3}'`"
  if [ "$processo" != "$ORACLE_SID" ]; then
     echo "***** Problema ao iniciar a instancia ${ORACLE_SID}"   >> $LOG
     echo "***** O servidor pode estar num estado inconsistente." >> $LOG
     cat $LOG | mail -s "URGENTE!!!  Erro ao desligar a instancia ${ORACLE_SID} em `uname -n`" $oracle_mail
     exit 2
  fi

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Executa um analyze no banco de dados
#
db_analyze() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Executa um analyze no Database      |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  sqlplus -s "/ as sysdba" <<-EOF_ANALYZE
  SET     FEEDBACK  OFF
  SET     TRIMSPOOL ON
  SET     TERMOUT   OFF
  SET     PAGES     0
  SET     LINES     250
  SPOOL   ${EXECSQL}/${operation}_db_analyze.log
  EXECUTE DBMS_STATS.GATHER_DATABASE_STATS();
  SPOOL   OFF
  EXIT
EOF_ANALYZE
  egrep --color -n -B 2 '(ORA-|SP2-)' ${EXECSQL}/${operation}_db_analyze.log >> $LOG 2>> $LOG

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
  echo "  Analyze : Site -> $ORACLE_SID em `uname -n`"  >> $LOG
}

#
# Backup logico full (data pump)
# so apartir do Oracle 10g
#
backup_logico_pump() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup Logico - Full - Data Pump    |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  dumpfil=${ORACLE_SID}_pup_${DIA}.dmp
  dumplog=${ORACLE_SID}_pup_${DIA}.log

#  expdp $orausr/$orapwd@${ORACLE_SID} full=y directory=data_pump_dir_${ORACLE_SID} \
  expdp $orausr/$orapwd@${ORACLE_SID} full=y directory=DIARIODMPDIR \
        dumpfile=${dumpfil} logfile=${dumplog} >> $LOGPUP-full.log 2>> $LOGPUP-full.log
  # Lista a ultima linha do log
  #tail -n 1 ${PATHBKP}/export/${dumplog}         >> $LOG 2>> $LOG

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Backup logico schemas (data pump)
# so apartir do Oracle 10g
#
backup_logico_pump_schemas() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup Logico - Schemas - Data Pump |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  dumpfil=${ORACLE_SID}_pup_${DIA}_
  dumplog=${ORACLE_SID}_pup_${DIA}_

  sqlplus -s "/ as sysdba" <<-EOF_BACKUP_LOGICO_PUMP_SCHEMAS
  SET     FEEDBACK  OFF
  SET     TRIMSPOOL ON
  SET     TERMOUT   OFF
  SET     PAGES     0
  SET     PAGESIZE  0
  SET     LINES     250
  SET     LINESIZE  500
  SPOOL   ${EXECSQL}/${operation}_db_backup_pump_schemas.out
    SELECT '!expdp ${orausr}/${orapwd}@${ORACLE_SID}' ||
           ' schemas=' || username ||
           ' directory=data_pump_dir_${ORACLE_SID}' ||
           ' dumpfile=${dumpfil}' || LOWER(username) || '.dmp' ||
           ' logfile=${dumplog}' || LOWER(username) || '.log' ||
           ' >> ${LOGPUP}-schemas.log 2>> ${LOGPUP}-schemas.log'
      FROM all_users
     WHERE username NOT IN ( 'ANONYMOUS'
                           , 'BI'
                           , 'CTXSYS'
                           , 'DBSNMP'
                           , 'DIP'
                           , 'DMSYS'
                           , 'EXFSYS'
                           , 'HR'
                           , 'IX'
                           , 'MDDATA'
                           , 'MDSYS'
                           , 'MGMT_VIEW'
                           , 'OE'
                           , 'OLAPSYS'
                           , 'ORACLE_OCM'
                           , 'ORDPLUGINS'
                           , 'ORDSYS'
                           , 'OUTLN'
                           , 'PM'
                           , 'SCOTT'
                           , 'SH'
                           , 'SI_INFORMTN_SCHEMA'
                           , 'SYS'
                           , 'SYSMAN'
                           , 'SYSTEM'
                           , 'TSMSYS'
                           , 'WMSYS'
                           , 'XDB'
                           )
  ORDER BY username;
  SPOOL   OFF
  @${EXECSQL}/${operation}_db_backup_pump_schemas.out
  EXIT
EOF_BACKUP_LOGICO_PUMP_SCHEMAS

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Backup logico full (export)
#
backup_logico_export() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup Logico - Full - Export       |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  dumpfil=${PATHBKP}/export/${ORACLE_SID}_exp_${DIA}.dmp
  dumplog=${PATHBKP}/export/${ORACLE_SID}_exp_${DIA}.log

  exp userid=$orausr/$orapwd@${ORACLE_SID} file=${dumpfil} log=${dumplog} \
      full=y consistent=y compress=y >> $LOGEXP-full.log 2>> $LOGEXP-full.log
  # Lista a ultima linha do log
  #tail -n 1 ${dumplog}                           >> $LOG 2>> $LOG

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Backup logico schemas (data pump)
#
backup_logico_export_schemas() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup Logico - Schemas - Export    |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  dumpfil=${PATHBKP}/export/${ORACLE_SID}_exp_${DIA}_
  dumplog=${PATHBKP}/export/${ORACLE_SID}_exp_${DIA}_

  sqlplus -s "/ as sysdba" <<-EOF_BACKUP_LOGICO_EXPORT_SCHEMAS
  SET     FEEDBACK  OFF
  SET     TRIMSPOOL ON
  SET     TERMOUT   OFF
  SET     PAGES     0
  SET     PAGESIZE  0
  SET     LINES     250
  SET     LINESIZE  500
  SPOOL   ${EXECSQL}/${operation}_db_backup_export_schemas.out
    SELECT '!exp userid=${orausr}/${orapwd}@${ORACLE_SID}' ||
           ' file=${dumpfil}' || LOWER(username) || '.dmp' ||
           ' log=${dumplog}' || LOWER(username) || '.log' ||
           ' owner=' || username ||
           ' consistent=y compress=y' ||
           ' >> ${LOGEXP}-schemas.log 2>> ${LOGEXP}-schemas.log'
      FROM all_users
     WHERE username NOT IN ( 'ANONYMOUS'
                           , 'BI'
                           , 'CTXSYS'
                           , 'DBSNMP'
                           , 'DIP'
                           , 'DMSYS'
                           , 'EXFSYS'
                           , 'HR'
                           , 'IX'
                           , 'MDDATA'
                           , 'MDSYS'
                           , 'MGMT_VIEW'
                           , 'OE'
                           , 'OLAPSYS'
                           , 'ORACLE_OCM'
                           , 'ORDPLUGINS'
                           , 'ORDSYS'
                           , 'OUTLN'
                           , 'PM'
                           , 'SCOTT'
                           , 'SH'
                           , 'SI_INFORMTN_SCHEMA'
                           , 'SYS'
                           , 'SYSMAN'
                           , 'SYSTEM'
                           , 'TSMSYS'
                           , 'WMSYS'
                           , 'XDB'
                           )
  ORDER BY username;
  SPOOL   OFF
  @${EXECSQL}/${operation}_db_backup_export_schemas.out
  EXIT
EOF_BACKUP_LOGICO_EXPORT_SCHEMAS

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Backup fisico on-line verifica se banco esta em modo de archiving
# se nao estiver, altera para archiving
#
backup_fisico_check_archiving() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup Fisico Check Archiving       |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  sqlplus -s "/ as sysdba" <<-EOF_BACKUP_FISICO_CHECK_ARCHIVING
  SET     FEEDBACK  OFF
  SET     TRIMSPOOL ON
  SET     TERMOUT   OFF
  SET     PAGES     0
  SET     PAGESIZE  0
  SET     LINES     250
  SET     LINESIZE  500
  SPOOL   ${EXECSQL}/check_archiving.log
    SELECT log_mode
      FROM gv\$database;
  SPOOL   OFF
  EXIT
EOF_BACKUP_FISICO_CHECK_ARCHIVING
  archiving=`cat ${EXECSQL}/check_archiving.log`
  if [ "$archiving" = "NOARCHIVELOG" ]; then
     sqlplus -s "/ as sysdba" <<-EOF_BACKUP_FISICO_ENABLE_ARCHIVING
     SHUTDOWN ABORT
     STARTUP
     SHUTDOWN IMMEDIATE
     STARTUP MOUNT
     ALTER DATABASE ARCHIVELOG;
     ALTER DATABASE OPEN;
     EXIT
EOF_BACKUP_FISICO_ENABLE_ARCHIVING
  fi

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Backup fisico on-line
#
backup_fisico_online() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup Fisico On-Line               |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  sqlplus -s "/ as sysdba" <<-EOF_BACKUP_FISICO_ON_LINE
  SET     FEEDBACK  OFF
  SET     TRIMSPOOL ON
  SET     TERMOUT   OFF
  SET     PAGES     0
  SET     PAGESIZE  0
  SET     LINES     250
  SET     LINESIZE  500
  SPOOL   ${EXECSQL}/${operation}_db_backup_fisico_on_line.out
    SELECT 'ALTER SYSTEM CHECKPOINT;'
      FROM DUAL;
    SELECT command
      FROM (SELECT '2' ordem
                 , tablespace_name
                 , 'ALTER TABLESPACE ' || tablespace_name || ' BEGIN BACKUP;' command
              FROM dba_tablespaces
             WHERE contents          != 'TEMPORARY'
            UNION
            SELECT '3' ordem
                 , a.tablespace_name
                 , '!cp ' || file_name || ' ${PATHBKP}/datafiles/' ||
                   SUBSTR(file_name, (INSTR(file_name, '/', -1, 1) + 1), LENGTH(file_name)) ||
                   ' 2>> ${LOG}' command
              FROM dba_data_files  a
                 , dba_tablespaces b
             WHERE a.tablespace_name  = b.tablespace_name
               AND contents          != 'TEMPORARY'
            UNION
            SELECT '4' ordem
                 , tablespace_name
                 , 'ALTER TABLESPACE ' || tablespace_name || ' END   BACKUP;' command
              FROM dba_tablespaces
             WHERE contents          != 'TEMPORARY'
           )
  ORDER BY tablespace_name
         , ordem;
    SELECT 'ALTER SYSTEM ARCHIVE LOG CURRENT;'
      FROM DUAL;
  SPOOL   OFF
  SET     PAGES     50
  SPOOL   ${EXECSQL}/${operation}_db_backup_fisico_on_line.log
  @${EXECSQL}/${operation}_db_backup_fisico_on_line.out
  SPOOL   OFF
  EXIT
EOF_BACKUP_FISICO_ON_LINE
  egrep --color -n -B 2 '(ORA-|SP2-)' ${EXECSQL}/${operation}_db_backup_fisico_on_line.out >> $LOG 2>> $LOG
  egrep --color -n -B 2 '(ORA-|SP2-)' ${EXECSQL}/${operation}_db_backup_fisico_on_line.log >> $LOG 2>> $LOG

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Backup fisico off-line
#
backup_fisico_offline() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup Fisico Off-Line              |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  for p in ${dados[*]}; do
      cp ${p}/${ORACLE_SID}/* ${PATHBKP}/datafiles 2>> $LOG
  done

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Compara arquivos fisicos: origem <==> destino
#
backup_fisico_compara_arquivos() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup Fisico Compara Arquivos      |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  echo "          : Origen"                      >> $LOG
  for p in ${dados[*]}; do
      du -hs ${p}/${ORACLE_SID} --exclude temp* >> $LOG 2>> $LOG
  done

  echo "          : Destino"                     >> $LOG
  for p in ${dados[*]}; do
      du -hs ${PATHBKP}/datafiles --exclude temp* >> $LOG 2>> $LOG
  done

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Backup control file
#
backup_control_file() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup Control File                 |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG
  echo "            Gerando control file em: ${PATHBKP}/controlfile" >> $LOG

  sqlplus -s "/ as sysdba" <<-EOF_BACKUP_CONTROL_FILE
  SET     FEEDBACK  OFF
  SET     TRIMSPOOL ON
  SET     TERMOUT   OFF
  SET     PAGES     0
  SET     PAGESIZE  0
  SET     LINES     250
  SET     LINESIZE  500
  SPOOL   ${EXECSQL}/${operation}_db_backup_control_file.out
    SELECT '!cp ' || par.value || '/' || '*' ||
--         ins.instance_name || '_ora_' || pro.spid ||
           '_control_file.trc ${PATHBKP}/controlfile/control_file_backup.sql 2>> ${LOG}'
      FROM v\$parameter par
         , v\$instance  ins
         , v\$process   pro
         , v\$session   ses
     WHERE par.name  = 'user_dump_dest'
       AND ses.sid   = SYS_CONTEXT('USERENV', 'SID')
       AND ses.paddr = pro.addr;
  SPOOL   OFF
  SPOOL   ${EXECSQL}/${operation}_db_backup_control_file.log
  ALTER   SESSION SET TRACEFILE_IDENTIFIER = 'control_file';
  ALTER   DATABASE BACKUP CONTROLFILE TO TRACE;
  ALTER   SESSION SET TRACEFILE_IDENTIFIER = '';
  @${EXECSQL}/${operation}_db_backup_control_file.out
  ALTER   DATABASE BACKUP CONTROLFILE TO '${PATHBKP}/controlfile/control_file_backup.bin' REUSE;
  SPOOL   OFF
  EXIT
EOF_BACKUP_CONTROL_FILE
  egrep --color -n -B 2 '(ORA-|SP2-)' ${EXECSQL}/${operation}_db_backup_control_file.out >> $LOG 2>> $LOG
  egrep --color -n -B 2 '(ORA-|SP2-)' ${EXECSQL}/${operation}_db_backup_control_file.log >> $LOG 2>> $LOG

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Backup control file
#
backup_spfile() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup spfile                       |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG
  echo "            Gerando spfile em: ${ORACLE_HOME}/dbs/init${ORACLE_SID}_backup.ora" >> $LOG

  # So funciona se o spfile existir
  if [ -f ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora ]; then
     # So pode ser executado pelo usuario Oracle do SO
     if [ $USER != 'oracle' ]; then
        echo "***** A operacao de backup do spfile nao e valida com o usuario $USER" >> $LOG
        echo "***** tente novamente com o usuario oracle do SO."                     >> $LOG
        exit 2
     fi
     sqlplus -s "/ as sysdba" <<-EOF_BACKUP_SPFILE
     SET     FEEDBACK  OFF
     SET     TRIMSPOOL ON
     SET     TERMOUT   OFF
     SET     PAGES     0
     SET     PAGESIZE  0
     SET     LINES     250
     SET     LINESIZE  500
     SPOOL   ${EXECSQL}/${operation}_db_backup_spfile.log
     CREATE   PFILE='${ORACLE_HOME}/dbs/init${ORACLE_SID}_backup.ora'
       FROM  SPFILE='${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora' ;
     SPOOL   OFF
     EXIT
EOF_BACKUP_SPFILE
  else
     echo "SPFILE ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora nao encontrado!" >> $LOG
  fi

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Move archives
#
backup_move_archives() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup Move Archives                |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  #mv -f ${ORACLE_HOME}/dbs/*.arc ${PATHBKP}/dbs  >> $LOG 2>> $LOG
  mv -f ${PATHARC}/* ${PATHBKP}/archive          >> $LOG 2>> $LOG

  if [ -d ${ORACLE_BASE}/oradata/${ORACLE_SID}/archive ]; then
     mv -f ${ORACLE_BASE}/oradata/${ORACLE_SID}/archive/*.arc ${PATHBKP}/archive >> $LOG 2>> $LOG
  fi

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Move trace files
#
backup_move_traces() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup Move Archives                |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  mv -f ${ORACLE_BASE}/admin/${ORACLE_SID}/adump/*.aud ${PATHBKP}/adump  >> $LOG 2>> $LOG
  mv -f ${ORACLE_BASE}/admin/${ORACLE_SID}/adump/*.trc ${PATHBKP}/adump  >> $LOG 2>> $LOG

  mv -f ${ORACLE_BASE}/admin/${ORACLE_SID}/bdump/*.aud ${PATHBKP}/bdump  >> $LOG 2>> $LOG
  mv -f ${ORACLE_BASE}/admin/${ORACLE_SID}/bdump/*.trc ${PATHBKP}/bdump  >> $LOG 2>> $LOG

  mv -f ${ORACLE_BASE}/admin/${ORACLE_SID}/cdump/*.aud ${PATHBKP}/cdump  >> $LOG 2>> $LOG
  mv -f ${ORACLE_BASE}/admin/${ORACLE_SID}/cdump/*.trc ${PATHBKP}/cdump  >> $LOG 2>> $LOG

  mv -f ${ORACLE_BASE}/admin/${ORACLE_SID}/dpdump/*    ${PATHBKP}/dpdump >> $LOG 2>> $LOG
  mv -f ${ORACLE_BASE}/admin/${ORACLE_SID}/dpdump/*    ${PATHBKP}/dpdump >> $LOG 2>> $LOG

  mv -f ${ORACLE_BASE}/admin/${ORACLE_SID}/udump/*.aud ${PATHBKP}/udump  >> $LOG 2>> $LOG
  mv -f ${ORACLE_BASE}/admin/${ORACLE_SID}/udump/*.trc ${PATHBKP}/udump  >> $LOG 2>> $LOG

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Compacta os backups feitos
#
compacta_backup_noturno() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Compacta Backup                     |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG


  #Alteracao Feita pelo Dba Andre Baracho em 20/10/11
  
  tar -cjf ${PATHBKP}/compress/${operation}-adump-${DIA}.tar.bz ${PATHBKP}/adump/* 2>> $LOG
  tar -jtvf ${PATHBKP}/compress/${operation}-adump-${DIA}.tar.bz >> $LOG 2>> $LOG
  echo >> $LOG
  echo " Removendo os arquivos de origem adump" >> $LOG
         rm -f ${PATHBKP}/adump/* 2>> $LOG
  echo >> $LOG
  tar -cjf ${PATHBKP}/compress/${operation}-archive-${DIA}.tar.bz ${PATHBKP}/archive/* 2>> $LOG
  tar -jtvf ${PATHBKP}/compress/${operation}-archive-${DIA}.tar.bz >> $LOG 2>> $LOG
  echo >> $LOG
  echo " Removendo os arquivos de origem archive" >> $LOG
         rm -f ${PATHBKP}/archive/* 2>> $LOG
  echo  >> $LOG
  tar -cjf ${PATHBKP}/compress/${operation}-bdump-${DIA}.tar.bz ${PATHBKP}/bdump/* 2>> $LOG
  tar -jtvf ${PATHBKP}/compress/${operation}-bdump-${DIA}.tar.bz >> $LOG 2>> $LOG
  echo >> $LOG
  echo " Removendo os arquivos de origem bdump" >> $LOG
         rm -f ${PATHBKP}/bdump/* 2>> $LOG
  echo >> $LOG
  tar -cjf ${PATHBKP}/compress/${operation}-cdump-${DIA}.tar.bz ${PATHBKP}/cdump/* 2>> $LOG
  tar -jtvf ${PATHBKP}/compress/${operation}-cdump-${DIA}.tar.bz >> $LOG 2>> $LOG
  echo >> $LOG
  echo " Removendo os arquivos de origem cdump" >> $LOG
         rm -f ${PATHBKP}/cdump/* 2>> $LOG
  echo >> $LOG
  tar -cjf ${PATHBKP}/compress/${operation}-controlfile-${DIA}.tar.bz ${PATHBKP}/controlfile/* 2>> $LOG
  tar -jtvf ${PATHBKP}/compress/${operation}-controlfile-${DIA}.tar.bz >> $LOG 2>> $LOG
  echo >> $LOG
  echo " Removendo os arquivos de origem controlfile" >> $LOG
         rm -f ${PATHBKP}/controlfile/* 2>> $LOG
  echo >> $LOG
  tar -cjf ${PATHBKP}/compress/${operation}-datafiles-${DIA}.tar.bz ${PATHBKP}/datafiles/* 2>> $LOG
  tar -jtvf ${PATHBKP}/compress/${operation}-datafiles-${DIA}.tar.bz >> $LOG 2>> $LOG
  echo >> $LOG
  echo " Removendo os arquivos de origem datafiles" >> $LOG
         rm -f ${PATHBKP}/datafiles/* 2>> $LOG
  echo >> $LOG
  tar -cjf ${PATHBKP}/compress/${operation}-dbs-${DIA}.tar.bz ${PATHBKP}/dbs/* 2>> $LOG
  tar -jtvf ${PATHBKP}/compress/${operation}-dbs-${DIA}.tar.bz >> $LOG 2>> $LOG
  echo >> $LOG
  echo " Removendo os arquivos de origem dbs" >> $LOG
         rm -f ${PATHBKP}/dbs/* 2>> $LOG
  echo >> $LOG
  tar -cjf ${PATHBKP}/compress/${operation}-dpdump-${DIA}.tar.bz ${PATHBKP}/dpdump/* 2>> $LOG
  tar -jtvf ${PATHBKP}/compress/${operation}-dpdump-${DIA}.tar.bz >> $LOG 2>> $LOG
  echo >> $LOG
  echo " Removendo os arquivos de origem dpdump" >> $LOG
         rm -f ${PATHBKP}/dpdump/* 2>> $LOG
  echo >> $LOG
  tar -cjf ${PATHBKP}/compress/${operation}-export-${DIA}.tar.bz ${PATHBKP}/export/* 2>> $LOG
  tar -jtvf ${PATHBKP}/compress/${operation}-export-${DIA}.tar.bz >> $LOG 2>> $LOG
  echo >> $LOG
  echo " Removendo os arquivos de origem export" >> $LOG
         rm -f ${PATHBKP}/export/* 2>> $LOG
  echo >> $LOG
  tar -cjf ${PATHBKP}/compress/${operation}-sql-${DIA}.tar.bz ${PATHBKP}/sql/* 2>> $LOG
  tar -jtvf ${PATHBKP}/compress/${operation}-sql-${DIA}.tar.bz >> $LOG 2>> $LOG
  echo >> $LOG
  echo " Removendo os arquivos de origem sql" >> $LOG
         rm -f ${PATHBKP}/sql/* 2>> $LOG
  echo >> $LOG
  tar -cjf ${PATHBKP}/compress/${operation}-udump-${DIA}.tar.bz ${PATHBKP}/udump/* 2>> $LOG
  tar -jtvf ${PATHBKP}/compress/${operation}-udump-${DIA}.tar.bz >> $LOG 2>> $LOG
  echo >> $LOG
  echo " Removendo os arquivos de origem udump" 2>> $LOG
         rm -f ${PATHBKP}/udump/* 2>> $LOG
  echo >> $LOG




  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Limpeza de arquivos
#
limpa_arquivos() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Limpeza dos arquivos com mais de 8d |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  echo "            Limpando = ${PATHBKP}/adump" >> $LOG
  find ${PATHBKP}/adump  -daystart -mtime +8 -exec rm -fv \{\} \; >> $LOG 2>> $LOG

  echo "            Limpando = ${PATHBKP}/bdump" >> $LOG
  find ${PATHBKP}/bdump  -daystart -mtime +8 -exec rm -fv \{\} \; >> $LOG 2>> $LOG

  echo "            Limpando = ${PATHBKP}/cdump" >> $LOG
  find ${PATHBKP}/cdump  -daystart -mtime +8 -exec rm -fv \{\} \; >> $LOG 2>> $LOG

  echo "            Limpando = ${PATHBKP}/dpdump" >> $LOG
  find ${PATHBKP}/dpdump -daystart -mtime +8 -exec rm -fv \{\} \; >> $LOG 2>> $LOG

  echo "            Limpando = ${PATHBKP}/udump" >> $LOG
  find ${PATHBKP}/udump  -daystart -mtime +8 -exec rm -fv \{\} \; >> $LOG 2>> $LOG

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Limpeza dos Backups Anteriores
#
limpa_backup_anterior() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Limpeza dos backups anteriores      |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  #  rm -f ${PATHBKP}/${operation}*
  rm -f ${PATHBKP}/adump/*.aud
  rm -f ${PATHBKP}/archive/*.arc
  rm -f ${PATHBKP}/bdump/*.trc
  rm -f ${PATHBKP}/cdump/*
  rm -f ${PATHBKP}/compress/${operation}*
  rm -f ${PATHBKP}/controlfile/*
  rm -f ${PATHBKP}/datafiles/*
  rm -f ${PATHBKP}/dbs/*
  rm -f ${PATHBKP}/dpdump/*
  rm -f ${PATHBKP}/export/*
  rm -f ${PATHBKP}/sql/${operation}*
  rm -f ${PATHBKP}/udump/*.trc
  rm -f /backup/expdp/diario/*
  rm -f /backup/online/full/*

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}

#
# Rotina principal
#
case $operation in
     'copia_archives')
     ;;
     'backup_noturno')
        echo "+----------------------------------------------------------------+"      >> $LOG
        echo "| Rotina  : Backup Noturno                                       |"      >> $LOG
        echo "| Inicio  : "`date +%Y-%m-%d-%R:%S`"                                  |" >> $LOG
        echo "| Em      : "`uname -n`                                                  >> $LOG
        echo "+----------------------------------------------------------------+"      >> $LOG
        #limpa_arquivos
        #limpa_backup_anterior
        verifica_backup_path
        verifica_discos
        verifica_site_on_line
        verifica_data_files
        verifica_alert
        verifica_tablespaces
        mostra_espaco_discos
        define_mes_anterior
        db_analyze
        backup_logico_pump
        backup_logico_pump_schemas
        backup_logico_export
        backup_logico_export_schemas
        backup_fisico_check_archiving
        backup_fisico_online
        backup_fisico_compara_arquivos
        backup_control_file
        backup_spfile
        backup_move_archives
        backup_move_traces
        compacta_backup_noturno
        echo ""                                                                        >> $LOG
        echo "+----------------------------------------------------------------+"      >> $LOG
        echo "| Rotina  : Backup Noturno                                       |"      >> $LOG
        echo "| Termino : "`date +%Y-%m-%d-%R:%S`"                                  |" >> $LOG
        echo "| Log em  : $LOG"                                                        >> $LOG
        echo "+----------------------------------------------------------------+"      >> $LOG
        cat $LOG | mail -s "Log do backup noturno de `uname -n`/${DIA}" $oracle_mail
     ;;
     'backup_noturno_diario')
        echo "+----------------------------------------------------------------+"      >> $LOG
        echo "| Rotina  : Backup Noturno Diario                                |"      >> $LOG
        echo "| Inicio  : "`date +%Y-%m-%d-%R:%S`"                                  |" >> $LOG
        echo "| Em      : "`uname -n`                                                  >> $LOG
        echo "+----------------------------------------------------------------+"      >> $LOG
        #limpa_arquivos
        limpa_backup_anterior
        verifica_backup_path
        verifica_discos
        verifica_site_on_line
        verifica_data_files
        verifica_alert
        verifica_tablespaces
        mostra_espaco_discos
        define_mes_anterior
        db_analyze
        backup_logico_pump
        backup_logico_pump_schemas
        backup_logico_export
        backup_logico_export_schemas
        backup_move_archives
        backup_move_traces
        compacta_backup_noturno
        echo ""                                                                        >> $LOG
        echo "+----------------------------------------------------------------+"      >> $LOG
        echo "| Rotina  : Backup Noturno Diario                                |"      >> $LOG
        echo "| Termino : "`date +%Y-%m-%d-%R:%S`"                                  |" >> $LOG
        echo "| Log em  : $LOG"                                                        >> $LOG
        echo "+----------------------------------------------------------------+"      >> $LOG
        cat $LOG | mail -s "Log do backup noturno diario de `uname -n`/${DIA}" $oracle_mail
     ;;
     'backup_off_line')
        echo "+----------------------------------------------------------------+"      >> $LOG
        echo "| Rotina  : Backup Off Line                                      |"      >> $LOG
        echo "| Inicio  : "`date +%Y-%m-%d-%R:%S`"                                  |" >> $LOG
        echo "| Em      : "`uname -n`                                                  >> $LOG
        echo "+----------------------------------------------------------------+"      >> $LOG
        verifica_backup_path
        verifica_discos
        verifica_site_on_line
        verifica_data_files
        verifica_alert
        verifica_tablespaces
        mostra_espaco_discos
        define_mes_anterior
        db_shutdown
        backup_fisico_offline
        db_startup
        echo ""                                                                        >> $LOG
        echo "+----------------------------------------------------------------+"      >> $LOG
        echo "| Rotina  : Backup Off Line                                      |"      >> $LOG
        echo "| Termino : "`date +%Y-%m-%d-%R:%S`"                                  |" >> $LOG
        echo "| Log em  : $LOG"                                                        >> $LOG
        echo "+----------------------------------------------------------------+"      >> $LOG
        cat $LOG | mail -s "Log do backup off line de `uname -n`/${DIA}" $oracle_mail
     ;;
     'rotina_mensal')
        echo "+----------------------------------------------------------------+"      >> $LOG
        echo "| Rotina  : Backup Mensal                                        |"      >> $LOG
        echo "| Inicio  : "`date +%Y-%m-%d-%R:%S`"                                  |" >> $LOG
        echo "| Em      : "`uname -n`                                                  >> $LOG
        echo "+----------------------------------------------------------------+"      >> $LOG
        echo ""                                                                        >> $LOG
        echo "+----------------------------------------------------------------+"      >> $LOG
        echo "| Rotina  : Backup Mensal                                        |"      >> $LOG
        echo "| Termino : "`date +%Y-%m-%d-%R:%S`"                                  |" >> $LOG
        echo "| Log em  : $LOG"                                                        >> $LOG
        echo "+----------------------------------------------------------------+"      >> $LOG
        cat $LOG | mail -s "Log da rotina mensal de `uname -n`/${DIA}" $oracle_mail
     ;;
     *)
        echo "***** A operacao ${operation} nao e valida" >> $LOG
        echo "***** chamada $0 $* ilegal"
        echo "***** uso: $0 " >> $LOG
     ;;
esac


#Limpeza de todos os arquivos que foram compactados
#Acrescimo feito pelo DBA Andre em 02_09_11


  rm -f /u05/oracle/backup/DIRETORIO/adump/*
  rm -f /u05/oracle/backup/DIRETORIO/archive/*
  rm -f /u05/oracle/backup/DIRETORIO/bdump/*
  rm -f /u05/oracle/backup/DIRETORIO/dpdump/*
  rm -f /u05/oracle/backup/DIRETORIO/export/*
  #rm -f /u05/oracle/backup/DIRETORIO/sql/${operation}*
  rm -f /u05/oracle/backup/DIRETORIO/udump/*

