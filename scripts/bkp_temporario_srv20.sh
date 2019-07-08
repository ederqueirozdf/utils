#export ORACLE_SID=BANCODSV
export ORACLE_BASE=/u01/oracle
export ORACLE_HOME=${ORACLE_BASE}/product/10g
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib
export NLS_LANG=AMERICAN_AMERICA.WE8ISO8859P1
export PATH=$PATH:${ORACLE_HOME}/bin
export PATHSQL=${ORACLE_BASE}/etc/sql
export PATHSCR=${ORACLE_BASE}/etc/script
export PATHBKP=/backup/oracle/${ORACLE_SID}/log
#      export PATHARC=${ORACLE_BASE}/flash_recovery_area/${ORACLE_SID}/archivelog
export PATHARC=${ORACLE_BASE}/oradata/srv20/archive
export EXECSQL=${PATHBKP}/sql
export DIA=`date +%Y-%m-%d-%H%M%S`
export LOG=${PATHBKP}/backup_full_datapump-${DIA}.log
export LOGPUP=${PATHBKP}/backup_full_datapump-${DIA}-pup
export LOGEXP=${PATHBKP}/backup_full_datapump-${DIA}-exp
export DEST_REMOTO=seu_servidor_remoto_de_backup

orausr=system
orapwd=DSVoracle

backup_logico_pump() {
  echo ""                                        >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "| Backup Logico - Full - Data Pump    |" >> $LOG
  echo "+-------------------------------------+" >> $LOG
  echo "  Inicio  : "`date +%Y-%m-%d-%R:%S`      >> $LOG

  dumpfil=${ORACLE_SID}_pup_${DIA}.dmp
  dumplog=${ORACLE_SID}_pup_${DIA}.log

  expdp $orausr/$orapwd@${ORACLE_SID} full=y exclude=schema:\"= \'RESTORE_PROT\'\" directory=DMPDIR \
        dumpfile=${dumpfil} logfile=${dumplog} >> $LOGPUP-full.log 2>> $LOGPUP-full.log
  # Lista a ultima linha do log
  #tail -n 1 ${PATHBKP}/export/${dumplog}         >> $LOG 2>> $LOG

  echo "  Termino : "`date +%Y-%m-%d-%R:%S`      >> $LOG
}
