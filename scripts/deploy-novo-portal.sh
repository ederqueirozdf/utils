#!/bin/bash

# Script de deploy para novas aplicações em homologação WEBSIS
# Wordpress ou Joomla
# Para cada aplicação é configurado um volume específico em LVM

DATA=`date +%d-%m-%Y-%H:%M:%S`
LV=/dev/mapper/vol-
FSTAB=/etc/fstab
TEMP=/tmp/

WORDPRESS=https://br.wordpress.org/latest-pt_BR.tar.gz
JOOMLA=https://downloads.joomla.org/br/cms/joomla3/3-9-11/Joomla_3-9-11-Stable-Full_Package.tar.gz?format=gz
WORKDIRWP=/Wordpress/
WORKDIRJOOMLA=/Joomla/
TARWP=latest-pt_BR.tar.gz
TARJOOMLA=Joomla_3-9-11-Stable-Full_Package.tar.gz

USRAPACHE=apache
APACHE=/etc/httpd/conf.d/
EMAIL=abuse@mma.gov.br
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
	echo "6. CONFIGURAÇÃO DO VHOST APACHE (homolog-nome.mma.gov.br)"
	echo "7. REINICIALIZAÇÃO DOS SERVIÇOS APACHE"
	echo "-----------------------------------------------------------------------------------------"
echo ""
	echo "** ATENÇÃO: ** Geralmente o nome do volume reflete o nome da aplicação"
	echo "** EXEMPLO: ** Requisição para homolog-conama.mma.gov.br o nome do volume deverá ser conama "
echo ""

### Verifica espaço disponível LVM
	echo "-----------------"
	echo "VERIFICA ESPAÇO DISPONÍVEL EM LVM"
	echo "-----------------"
echo ""
	echo "ESPAÇO DISPONÍVEL EM $DATA:"
   	  vgdisplay  | grep Free | awk -F "<" {'print $2'}
echo ""
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

}


VERIFICALVM(){
echo ""
        echo "-----------------"
        echo "VALIDA VOLUME CRIADO"
        echo "-----------------"
echo ""
	lvdisplay $LV$NOMEVOL

	if [ $? -eq 0 ]
	 then
	  echo "Volume criado com êxito"
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
	echo "    DocumentRoot $WORKDIRWP$NOMEVOL" >> $APACHE$NOMEVOL.conf
	echo "    ServerName homolog-$NOMEVOL.mma.gov.br" >> $APACHE$NOMEVOL.conf
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
        echo "    ServerName homolog-$NOMEVOL.mma.gov.br" >> $APACHE$NOMEVOL.conf
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

}

CRIALVM
VERIFICALVM
FORMATALVM
CMS
