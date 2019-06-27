#!/bin/bash

LIST=$( cat usuarios.txt )
PASS='Senha'


######################################
# Conversao de arquivo DOS para UNIX##
######################################

converter()
{
/usr/bin/dos2unix usuarios.txt
}

#############################################
# Laco de verificacao e exclusao de usuario #
#############################################

dell_user()
{



		for CPF in $LIST; do
				
				# Search CN for Users
				DN=$( ldapsearch -xLLL -b o=mma -s sub cn=$CPF | grep dn: | awk '{print $2}' )
				NAME=$( ldapsearch -xLLL -b o=mma -s sub cn=$CPF | grep fullName: | awk '{print $2}' )
				
			if [ ! -z "$DN" ]; then

				echo " "
				echo "O DN para o $CPF is $DN"
				echo " "

				echo "Removendo usuario: $NAME CPF: $CPF..."
				echo " "

				# Dell user LDAP
				ldapdelete -v -x -D "cn=master,o=mma" -w "$PASS" "$DN"
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
	dell_user
}

# Execucao script
main

