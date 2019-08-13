    #!/bin/bash

# Version: 1.0
# Date of create: 13/08/2019
# Create by: Eder Queiroz
# Description: Script para criação de usuários no Linux e permissão de acesso ao samba para grupo diretórios com grupo N2.

    LIST=$( cat lista.txt)

    IFSOLD=$IFS
    IFS=$'\n'

           for CPF in $LIST
             do
            LOGIN=$(echo $CPF | awk -F"-" '{print $1}')
            NAME=$(echo $CPF | awk -F"-" '{print $2}')
            echo " Adicionando o usuario $LOGIN para $NAME"
              adduser "$LOGIN" -c "$NAME" -s /bin/false
              usermod -G n2 "$LOGIN"
              echo -ne "$LOGIN\n$LOGIN\n" | smbpasswd -a "$LOGIN"

            done
           IFS=$IFS.OLD
