#!/bin/bash

LIST=$( cat usuarios.txt )
PASS='Senha'
BACKUPDIR=/opt/script/backup
LDAPBKP=ldap-$(date +%Y-%m-%d).ldif
LOG=script-$(date +%Y-%m-%d).log


######################################
# Conversao de arquivo DOS para UNIX##
######################################

converter()
{
/usr/bin/dos2unix usuarios.txt
}



###############################################
#### BACKUP DA BASE LDAP LINUX - SINCRONIZA ###
###############################################

backup_ldap()
{
	# Criando arquivo de log
	touch $LOG
	echo " Log de Execução de Script: $LOG" >> $LOG

        #Backup da Base LDAP - Sincroniza
        echo "" >> $LOG
        echo "Efetuando backup slapcat" >> $LOG
	echo "Realizando backup da base LDAP sincroniza"
        /usr/sbin/slapcat -v -b "NOMEBASELDAP" -l $BACKUPDIR/$LDAPBKP >> $LOG
	echo "" >> $LOG

}


###################################################
#### LAÇO PARA REMOÇÃO DE USUÁRIOS NA BASE LDAP ###
###################################################

dell_user()
{

		for CPF in $LIST; do
				
				echo "::Buscando usuarios::"
				# Busca CN usuario LDAP
				DN=$( ldapsearch -xLLL -b "BASELDAPAQUI" -s sub cn=$CPF | grep dn: | awk '{print $2}' )
				NAME=$( ldapsearch -xLLL -b "BASELDAPAQUI" -s sub cn=$CPF | grep fullName: | awk '{print $2}' )
				
			if [ ! -z "$DN" ]; then

				echo " "
				echo "O DN para o $CPF e: $DN"
				echo " "

				echo "::Removendo usuarios::"
				echo "Removendo usuario: $NAME CPF: $CPF..."
				echo " "

				# Deleta usuario LDAP
				ldapdelete -v -x -D "cn=master,DNBASELDAP" -w "$PASS" "$DN"
				echo " "
				echo "Fim!";

			else

				echo "O usuario $CPF nao existe"
				echo " "
				echo "Fim!"

				sleep 2

			fi

		done

}

main()
{
	converter
        backup_ldap
	dell_user
}

#execucao script
main
