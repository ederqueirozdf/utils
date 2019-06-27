#!/bin/bash
#
# Script Hepta - MMA
# Powered by Eder Queiroz
# Script para busca e remocao de usuarios no ldap do ministerio do meio ambiente.

LIST=$( cat usuarios.txt )
PASS='&Mm@000%'
BACKUPDIR=/opt/script/backup
LDAPBKP=ldap-$(date +%Y-%m-%d).ldif
LDAPBKPCONFIG=ldap-config-$(date +%Y-%m-%d).ldif
LOG=script-$(date +%Y-%m-%d).log



###############################################
#### BACKUP DA BASE LDAP LINUX - SINCRONIZA ###
###############################################

backup_ldap()
{
	# Criando arquivo de log
	touch $LOG
	echo " SCRIPT LOG DATA : $LOG" >> $LOG

        #Backup da Base LDAP - Sincroniza
        echo "" >> $LOG
        echo "Efetuando backup slapcat" >> $LOG
	echo " :: Realizando Backup da Base LDAP/Sincroniza ::"
	sleep 3
	echo ""
        /usr/sbin/slapcat -v -b "o=mma" -l $BACKUPDIR/$LDAPBKP >> $LOG
        echo "" >> $LOG
	echo "Efetuando backup slapcat CONFIG" >> $LOG
	echo " :: Realizando Backup Config ::"
	sleep 3
        echo "" >> $LOG
        /usr/sbin/slapcat -v -n 0 -l $BACKUPDIR/$LDAPBKPCONFIG >> $LOG
	echo "" >> $LOG

}



###################################################
#### LAÇO PARA REMOÇÃO DE USUÁRIOS NA BASE LDAP ###
###################################################

dell_user()
{

		for CPF in $LIST; do
				
				echo "::Buscando usuarios::" >> $LOG
				echo " :: Buscando usuario :: "
				# Busca CN usuario LDAP
				DN=$( ldapsearch -xLLL -b o=mma -s sub cn=$CPF | grep dn: | awk '{print $2}' )
				NAME=$( ldapsearch -xLLL -b o=mma -s sub cn=$CPF | grep fullName: | awk '{print $2}' )
				
			if [ ! -z "$DN" ]; then

				echo " " >> $LOG
				echo " O CPF: $CPF corresponde ao DN: $DN" >> $LOG
				echo " " >> $LOG

				echo "::Removendo usuarios::" >> $LOG
				echo "" >> $LOG
				echo ":: Removendo Usuarios da Base LDAP ::"
				echo " Removendo usuario: $NAME portador do CPF: $CPF..." >> $LOG
				echo " " >> $LOG

				# Deleta usuario LDAP
				ldapdelete -v -x -D "cn=master,o=mma" -w "$PASS" "$DN"
				echo " " >> $LOG
				echo "Fim!";

			else

				echo "O usuario $CPF nao foi encontrado" >> $LOG
				echo " " >> $LOG
				echo ":: Fim ::" >> $LOG
				echo ":: Fim ::"
				sleep 2

			fi

		done

}

main()
{
        backup_ldap
	dell_user
}

#execucao script
main
