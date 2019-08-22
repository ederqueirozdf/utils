#!/bin/bash

#------------------------------------------------------------------#
# Version: 1.0
# Date of create: 22/08/2019
# Create by: Eder Queiro - ederbritodf@gmail.com
# Description: Script de deploy para novas aplicações 
# em ambiente de homologação do MMA em CMS - Wordpress ou Joomla
# Para cada aplicação é configurado um volume específico em LVM
# PRÉ-REQUISITO: Configuração de DNS "homolog-nome$DOMINIO"
#------------------------------------------------------------------#

DATA=`date +%d-%m-%Y-%H:%M:%S`
LV=/dev/mapper/vol-
FSTAB=/etc/fstab
TEMP=/tmp/
DOMINIO=.seudominio.com.br

WORDPRESS=https://br.wordpress.org/latest-pt_BR.tar.gz
JOOMLA=https://downloads.joomla.org/br/cms/joomla3/3-9-11/Joomla_3-9-11-Stable-Full_Package.tar.gz?format=gz
WORKDIRWP=/Wordpress/
WORKDIRJOOMLA=/Joomla/
TARWP=latest-pt_BR.tar.gz
TARJOOMLA=Joomla_3-9-11-Stable-Full_Package.tar.gz

USRAPACHE=apache
APACHE=/etc/httpd/conf.d/
EMAIL=email@seudominio.com.br
LOG=/var/log/httpd/

CRIALVM(){
echo ""
	echo "---------------------------------------------------------------------------------------"
	echo "ESTE SCRIPT FOI CONFIGURADO PARA CRIAÇÃO DE INSTÂNCIAS WORDPRESS OU JOOMLA."
	echo "ESTE SERVIDOR POSSUI CONFIGURAÇÃO DE LVM PARA CADA WORKDIR DE CADA APLICAÇÃO EM CMS."
	echo "ESTE SCRIPT IRÁ REALIZADAS AS SEGUINTES CONFIGURAÇÕES:"
echo ""
	echo "1. CRIAÇÃO DE VOLUME LÓGICO SOBRE O GRUPO DE VOLUMES JÁ ENTREGUE (vol)"
	echo "2. FORMATAÇÃO DO VOLUME CRIADO EM XFS"
	echo "3. MONTAGEM NO ARQUIVO DE PARTIÇÕES LINUX (fstab)"
	echo "4. DOWNLOAD DA ÚLTIMA VERSÃO DO CMS JOOMLA ou WORDPRESS"
	echo "5. DESCOMPACTAÇÃO DO CMS NO WORKDIR DA APLICAÇÃO"
	echo "6. CONFIGURAÇÃO DO VHOST APACHE (homolog-nome$DOMINIO)"
	echo "7. REINICIALIZAÇÃO DOS SERVIÇOS APACHE"
	echo "-----------------------------------------------------------------------------------------"
echo ""
	echo "** ATENÇÃO: ** Geralmente o nome do volume reflete o nome da aplicação"
	echo "** EXEMPLO: ** Requisição para homolog-conama$DOMINIO o nome do volume deverá ser conama "
	echo "*** PRÉ-REQUISITO: *** Criar entrada DNS"
echo ""

# VERIFICAR ESPAÇO DISPONÍVEL NO LVM
	echo "-----------------"
	echo "VERIFICA ESPAÇO DISPONÍVEL EM LVM"
	echo "-----------------"
echo ""
	echo "ESPAÇO DISPONÍVEL EM $DATA:"
   	  vgdisplay  | grep Free | awk -F "<" {'print $2'}
echo ""

# CRIAÇÃO DE VOLUME LVM

	echo "-----------------"
	echo "CRIA VOLUME LÓGICO"
	echo "-----------------"
echo ""
	echo "INFORME O NOME DO VOLUME A SER CRIADO:"
	read NOMEVOL
echo ""
	echo "--------------------------"
	echo " NOME DO VOLUME: | $NOMEVOL "
	echo "--------------------------"
echo ""
	echo "Criando volume"
	sleep 1s
	echo "."
	sleep 2s
	echo ".."
	sleep 3s
	echo "..."

	lvcreate -L +5G -n $NOMEVOL vol
	
	VERIFICALVM
}


VERIFICALVM(){

# VALIDAÇÃO DO LVM CRIADO
# SE O RETORNO DA LISTAGEM FOR 0 EXECUTA A FORMATAÇÃO DO DISCO EM XFS
# SE FALHAR FINALIZAR O SCRIPT

echo ""
        echo "-----------------"
        echo "VALIDA VOLUME CRIADO"
        echo "-----------------"
echo ""
	lvdisplay $LV$NOMEVOL

	if [ $? -eq 0 ]
	 then
	  echo "Volume criado com êxito"
	  FORMATALVM
	 else
	  EXITLVM
	fi
}

EXITLVM(){
echo "FALHA AO CRIAR LVM"
exit
}

FORMATALVM(){
echo ""
        echo "-----------------"
        echo "FORMATA VOLUME LVM"
        echo "-----------------"
echo ""

	mkfs.xfs $LV$NOMEVOL

echo ""
	echo "BLKID para configuração das partições de montagem (FSTAB):"
echo ""
	blkid $LV$NOMEVOL

}

FSTABWP(){

#ALIMENTA O ARQUIVO DE PARTIÇÕES LINUX - FSTAB REFERENTE AO DIRETÓRIO WORDPRESS
#COM O ID DO DISCO SENDO MANIPULADO PELO CUT PEGANDO O RESULTADO BLKID
#SOMENTE A PARTE QUE CONTEM O UUID

echo ""
        echo "-----------------"
        echo "CONFIGURA FSTAB"
        echo "-----------------"
echo ""
        echo "CRIANDO DIRETÓRIO"
        mkdir $WORKDIRWP$NOMEVOL
	echo "" >> $FSTAB
	echo "#INSERT BY SCRIPT - $DATA | $NOMEVOL " >> $FSTAB
	blkid $LV$NOMEVOL
	BLKIDWP=$(blkid $LV$NOMEVOL | cut -d " " -f2)
	echo "$BLKIDWP $WORKDIRWP$NOMEVOL xfs defaults  0 0" >> $FSTAB
	mount -a

	DEPLOYWP

}

#ALIMENTA O ARQUIVO DE PARTIÇÕES LINUX - FSTAB REFERENTE AO DIRETÓRIO JOOMLA
#COM O ID DO DISCO SENDO MANIPULADO PELO CUT PEGANDO O RESULTADO BLKID
#SOMENTE A PARTE QUE CONTEM O UUID

FSTABJOOMLA(){
echo ""
        echo "-----------------"
        echo "CONFIGURA FSTAB"
        echo "-----------------"
echo ""
        echo "CRIANDO DIRETÓRIO"
        mkdir $WORKDIRJOOMLA$NOMEVOL
        echo "" >> $FSTAB
        echo "#INSERT BY SCRIPT - $DATA | $NOMEVOL " >> $FSTAB
        blkid $LV$NOMEVOL
        BLKIDJOOMLA=$(blkid $LV$NOMEVOL | cut -d " " -f2)
        echo "$BLKIDJOOMLA $WORKDIRJOOMLA$NOMEVOL xfs defaults  0 0" >> $FSTAB
	mount -a

	DEPLOYJOOMLA

}


CMS(){

# SESSÃO PARA VERIFICAÇÃO DE DEPLOY DO CMS ESCOLHIDO

echo ""
        echo "-----------------"
        echo "DEPLOY CMS"
        echo "-----------------"
echo ""
	echo "INFORME O TIPO DE CMS PARA O DEPLOY"
	echo "1 - WORDPRESS"
	echo "2 - JOOMLA"
	read DEPLOY

	 if [ $DEPLOY == 1 ]; then
	  echo "DEPLOY EM WORDPRESS INICIANDO ..."
#	  DEPLOYWP
	FSTABWP
	 elif [ $DEPLOY == 2 ]; then
	  echo "DEPLOY EM JOOMLA INICIANDO ..."
#	  DEPLOYJOOMLA
	FSTABJOOMLA
	 else
echo ""
	  echo "OPÇÃO INVÁLIDA."
	  echo "- - -"
	  echo " >>> INFORME 1 PARA DEPLOY EM WORDPRESS"
	  echo " >>> INFORME 2 PARA DEPLOY EM JOOMLA"
echo ""
	CMS
	fi
}

DEPLOYWP(){


#DEPLOY WORDPRESS
#DOWNLOAD DA ULTIMA VERSÃO DO CMS EM DIRETÓRIO TMP
#AO REALIZAR O DOWNLOAD DESCOMPACTAR PARA PASTA DESTINO
#E MOVER DO DIRETÓRIO PADRAO wordpress PARA O WORKDIR DA APLICAÇÃO

echo ""
        echo "-----------------"
        echo "DEPLOY WORDPRESS"
        echo "-----------------"
echo ""

echo ""
	echo "REALIZANDO DOWNLOAD WORDPRESS"
	/usr/bin/wget $WORDPRESS -P $TEMP
	tar -zxvf $TEMP$TARWP -C $WORKDIRWP$NOMEVOL
	mv $WORKDIRWP$NOMEVOL/wordpress/* $WORKDIRWP$NOMEVOL
	echo "PERMISSÃO APACHE"
        chown -R $USRAPACHE:"domain users" $WORKDIRWP$NOMEVOL
echo ""
	echo "REMOVE ARQUIVOS TEMPORARIOS"
	rm -rf $TEMP*
	VHOSTWP
}

DEPLOYJOOMLA(){

#DEPLOY JOOMLA
#DOWNLOAD DA ULTIMA VERSÃO DO CMS JOOMLA EM DIRETÓRIO TMP
#RENOMEIA ARQUIVO BAIXADO COM FORMAT\=GZ
#DESCOMPACTA EM DIRETÓRIO REFERENTE AO WORKDIR DA APLICAÇÃO

echo ""
        echo "-----------------"
        echo "DEPLOY JOOMLA"
        echo "-----------------"
echo ""

echo ""
        echo "REALIZANDO DOWNLOAD JOOMLA"
        /usr/bin/wget $JOOMLA -P $TEMP
	mv $TEMP$TARJOOMLA\?format\=gz $TEMP$TARJOOMLA
        tar -zxvf $TEMP$TARJOOMLA -C $WORKDIRJOOMLA$NOMEVOL
	echo "PERMISSÃO APACHE"
	chown -R $USRAPACHE:"domain users" $WORKDIRJOOMLA$NOMEVOL
echo ""
        echo "REMOVE ARQUIVOS TEMPORARIOS"
        rm -rf $TEMP*
	VHOSTJOOMLA
}

VHOSTWP(){

#CONFIGURA NOVO ARQUIVO .CONF "VIRTUALHOST" DO APACHE
#RECARREGA AS CONFIGURAÇÕES DO APACHE

echo ""
        echo "-----------------"
        echo "CONFIGURAÇÃO VHOST APACHE"
        echo "-----------------"
echo ""

	echo " CRIANDO vhost .CONF"
	touch $APACHE$NOMEVOL.conf
	echo "#-------------------------" >> $APACHE$NOMEVOL.conf
	echo "# INSERT BY SCRIPT - $DATA" >> $APACHE$NOMEVOL.conf
	echo "#-------------------------" >> $APACHE$NOMEVOL.conf
	echo "<VirtualHost *:80>" >> $APACHE$NOMEVOL.conf
	echo "    ServerAdmin $EMAIL" >> $APACHE$NOMEVOL.conf
	echo "    DocumentRoot $WORKDIRWP$NOMEVOL" >> $APACHE$NOMEVOL.conf
	echo "    ServerName homolog-$NOMEVOL$DOMINIO" >> $APACHE$NOMEVOL.conf
echo "" >> $APACHE$NOMEVOL.conf
	echo "#LOGS" >> $APACHE$NOMEVOL.conf
echo "" >> $APACHE$NOMEVOL.conf
	echo "    CustomLog $LOG$NOMEVOL.access.log combined" >> $APACHE$NOMEVOL.conf
	echo "    ErrorLog $LOG$NOMEVOL.error.log" >> $APACHE$NOMEVOL.conf
	echo "    Loglevel warn" >> $APACHE$NOMEVOL.conf
echo "" >> $APACHE$NOMEVOL.conf
	echo "#PERMISSOES DE DIRETORIO" >> $APACHE$NOMEVOL.conf
	echo "      <Directory $WORKDIRWP$NOMEVOL>" >> $APACHE$NOMEVOL.conf
	echo "        Options -Indexes" >> $APACHE$NOMEVOL.conf
	echo "        AllowOverride all" >> $APACHE$NOMEVOL.conf
	echo "        Require all granted" >> $APACHE$NOMEVOL.conf
	echo "      </Directory>" >> $APACHE$NOMEVOL.conf
echo "" >> $APACHE$NOMEVOL.conf
echo "</VirtualHost>" >> $APACHE$NOMEVOL.conf

echo ""
	echo "REINICIANDO APACHE"
	systemctl reload httpd
	VALIDAURL
}

VHOSTJOOMLA(){

echo ""
        echo "-----------------"
        echo "CONFIGURAÇÃO VHOST APACHE"
        echo "-----------------"
echo ""

        echo " CRIANDO .CONF"
        touch $APACHE$NOMEVOL.conf
        echo "#-------------------------" >> $APACHE$NOMEVOL.conf
        echo "# INSERT BY SCRIPT - $DATA" >> $APACHE$NOMEVOL.conf
        echo "#-------------------------" >> $APACHE$NOMEVOL.conf
        echo "<VirtualHost *:80>" >> $APACHE$NOMEVOL.conf
        echo "    ServerAdmin $EMAIL" >> $APACHE$NOMEVOL.conf
        echo "    DocumentRoot $WORKDIRJOOMLA$NOMEVOL" >> $APACHE$NOMEVOL.conf
        echo "    ServerName homolog-$NOMEVOL$DOMINIO" >> $APACHE$NOMEVOL.conf
echo "" >> $APACHE$NOMEVOL.conf
        echo "#LOGS" >> $APACHE$NOMEVOL.conf
echo "" >> $APACHE$NOMEVOL.conf
        echo "    CustomLog $LOG$NOMEVOL.access.log combined" >> $APACHE$NOMEVOL.conf
        echo "    ErrorLog $LOG$NOMEVOL.error.log" >> $APACHE$NOMEVOL.conf
        echo "    Loglevel warn" >> $APACHE$NOMEVOL.conf
echo "" >> $APACHE$NOMEVOL.conf
        echo "#PERMISSOES DE DIRETORIO" >> $APACHE$NOMEVOL.conf
        echo "      <Directory $WORKDIRJOOMLA$NOMEVOL>" >> $APACHE$NOMEVOL.conf
        echo "        Options -Indexes" >> $APACHE$NOMEVOL.conf
        echo "        AllowOverride all" >> $APACHE$NOMEVOL.conf
        echo "        Require all granted" >> $APACHE$NOMEVOL.conf
        echo "      </Directory>" >> $APACHE$NOMEVOL.conf
echo "" >> $APACHE$NOMEVOL.conf
echo "</VirtualHost>" >> $APACHE$NOMEVOL.conf

echo ""
        echo "REINICIANDO APACHE"
        systemctl reload httpd
	VALIDAURL
}

VALIDAURL(){

#VALIDA STATUS CODE DA PÁGINA UTILIZANDO O CURL.

echo ""
	echo "VALIDA URL:"
	CURL=$(curl -s -o /dev/null -w "%{http_code}" http://homolog-$NOMEVOL$DOMINIO)
	if [ $CURL == 200 ]; then
	  echo "SISTEMA DISPONÍVEL - STATUS: $CURL"
echo""
	  echo "----------------------------------------------"
	  echo " ACESSE: http://homolog-$NOMEVOL$DOMINIO "
	  echo "----------------------------------------------"
echo ""
	elif [ $CURL == 302 ]; then
          echo "SISTEMA DISPONÍVEL SENDO REDIRECIONADO - STATUS: $CURL"
echo ""	
          echo "----------------------------------------------"
          echo " ACESSE: http://homolog-$NOMEVOL$DOMINIO "
          echo "----------------------------------------------"
echo ""
	else
echo ""
	  echo "-----------------------------------------------------------"
	  echo "NÃO CONSEGUIMOS IDENTIFICAR O PROBLEMA NO ACESSO AO SISTEMA"
	  echo "STATUS COD: $CURL"
	  echo "TENTE ACESSAR A URL: http://homolog-$NOMEVOL$DOMINIO"
	  echo "-----------------------------------------------------------"
echo ""
echo ""
	fi
}

CRIALVM
CMS
