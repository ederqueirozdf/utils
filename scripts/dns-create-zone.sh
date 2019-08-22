#!/bin/sh
# Script para criação de zona DNS
# Nov. 2017, Eder Queiroz
# Readme: Script para criação de chaves de zona de DNS e configuração de ZONA com DNSSEC. Validade de chaves para assinatura de zonas configuradas para 03 meses.


# DIRETORIO DAS CHAVES DNSSEC
KSK=/var/named/ksk
ZSK=/var/named/zsk
echo""
echo "|----------------------------------------------|"
echo "|          CONFIGURE DNSSEC ZONE               |"
echo "|----------------------------------------------|"
echo ""
echo -e " FUNÇÕES DO SCRIPT:\n 01. Gerar Chaves DNSSEC; \n 02. Assinar ZONA DNSSEC; \n 03. Agendamento na CRON para renovação automática de validade das chaves.\n *OBS.:* As chaves geradas possuem validade de 03 meses.\n \n"
echo ":: INFORME O NOME DA ZONA :: (ex.: "seudominio.com")"
read ZONE

#GERANDO CHAVE KSK
echo "GERANDO A CHAVE "KSK" PARA A ZONA: $ZONE"
cd $KSK
	/usr/sbin/dnssec-keygen -r /dev/urandom -f KSK -a NSEC3RSASHA1 -b 4096 -n ZONE $ZONE
echo ""
echo "----------------------------------------------"
echo ""

#GERANDO CHAVE ZSK
echo ""
echo "----------------------------------------------"
echo "GERANDO A CHAVE "ZSK" PARA A ZONA: $ZONE"
cd $ZSK
	/usr/sbin/dnssec-keygen -r /dev/urandom -a NSEC3RSASHA1 -b 2048 -n ZONE $ZONE
echo ""
echo "----------------------------------------------"
echo ""

#ADICIONANDO CHAVES NO ARQUIVO DE ZONA DNS
echo "ADICIONANDO CHAVES NO ARQUIVO DA ZONA: $ZONE"
	cat ${KSK}/K${ZONE}.*.key ${ZSK}/K${ZONE}.*.key >> /var/named/${ZONE}.zone.ext
echo ""
echo "----------------------------------------------"
echo ""

#PRINTANDO A ZONA NA TELA 
echo "|----------------------------------------------|"
echo "|       VISUALIZACAO DA ZONA CONFIGURADA       |"
echo "|----------------------------------------------|"
	cat /var/named/${ZONE}.zone.ext
echo "|----------------------------------------------|"
echo "|           FIM DA ZONA CONFIGURADA            |"
echo "|----------------------------------------------|"
echo ""
echo ""
     echo "DESEJA ASSINAR A ZONA AGORA?"
	echo -e "1 - SIM\n2 - NÃO"
	read numero
	if [ $numero == 1 ]; then
	 bash /var/named/scripts/sign-zone.sh $ZONE 
	    echo ""
	    echo "----------------------------------------------"
	    echo ""
	    echo "DESEJA ADICIONAR O SCRIPT NA CRON?"
            echo -e "1 - SIM\n2 - NÃO"
            read cron
         if [ $cron == 1 ]; then
              echo "00 08 01 */3 * root bash /var/named/scripts/sign-zone.sh $ZONE" >> /etc/crontab
	      echo ""
	      echo "|----------------------------------------------|"
	      echo "|            VISUALIZAÇÃO DA CRON              |"
	      echo "|----------------------------------------------|"
	      cat /etc/crontab
           else
              echo "Bye"
         fi
        fi

