#!/bin/bash
# Script by Eder Queiroz - 24-04-2021
# Versão 1.0
# Script para configuração de regras de acesso a internet / caseiro.


#PROJETO
DIRCONFIG="/guerra"
REPOSITORIO=https://github.com/StevenBlack/hosts.git
IP="0.0.0.0"

#CORES
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${ORANGE}VALIDA PACOTES - PRE-REQUISITOS !!!" ${NC}

VERIFICAPKG(){
  
  VERIFICAGIT
  VERIFICAPY3
  
  }


VERIFICAGIT(){

echo -e "\n\n - ${ORANGE}VERIFICA GIT ${NC}"

  dpkg -s git
  if [ $? -eq 0 ]; then
  GITVERSION=$(dpkg -s git | grep -i version:)
     echo -e "${GREEN} Git instalado: $GITVERSION" ${NC}
   else
     echo -e "\n\n - ${ORANGE} INSTALANDO GIT ${NC}"
     sudo apt-get install git -y
  fi

}

VERIFICAPY3(){

 echo -e "\n\n - ${ORANGE}VERIFICA PYTHON3 ${NC}"

   dpkg -s python3
   if [ $? -eq 0 ]; then
   PY3VERSION=$(dpkg -s python3 | grep -i version:)
      echo -e "${GREEN} Python 3 instalado: $PY3VERSION" ${NC}
    else
      echo -e "\n\n - ${ORANGE} INSTALANDO PYTHON3 ${NC}"
      sudo apt-get install python3 -y
   fi

}


WORKDIR(){
  
  mkdir $DIRCONFIG
  if [ -d $DIRCONFIG ]; then
    echo -e "\n\n - ${GREEN} DIRETÓRIO $DIRCONFIG CRIADO ${NC}"
    WHITELIST
     else
       exit
  fi
  }

WHITELIST(){
  cd $DIRCONFIG
  LISTA=https://raw.githubusercontent.com/ederqueirozdf/utils/master/whitelist
  curl $LISTA --output whitelist
}

CONFIGURAREPO(){
  cd $DIRCONFIG
  echo -e "\n\n - ${ORANGE} DOWNLOAD HOSTS ${NC}"

  if [ -d hosts ]; then
      cd hosts
      git pull
      echo -e "${GREEN} Repositório atualizado ${NC}"
    else
      echo -e "${ORANGE} Baixando repsitorio ${NC}"
      git clone $REPOSITORIO
  fi

  
  }

HOSTS(){
 cd $DIRCONFIG/hosts
 echo -e "\n\n - ${ORANGE} REALIZANDO CONFIGURAÇÕES DE ACESSO RESTRITO  ${NC}" 
  python3 updateHostsFile.py --auto --replace --ip $IP --whitelist $DIRCONFIG/whitelist --extensions porn social gambling fakenews 
  if [ $? -eq 0 ]; then
      FINISH
    else
      echo -e "${RED} ERROR: VERIFIQUE OS LOGS! ${NC}"
  fi

  }

FINISH(){
  
  echo -e "${GREEN} CONFIGURAÇÃO FINALIZADA COM SUCESSO! ${NC}"
  
  }


VERIFICAPKG
WORKDIR
CONFIGURAREPO
HOSTS
