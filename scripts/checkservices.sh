#!/bin/bash

ORANGE='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'
NomeHost=$(hostname)


NetcatPorts(){
declare -a Lista=("host.url 443" "host.url2 443" "c 443" "host.url3 53" "e 53")

echo -e "\n==========> Teste de conectivade via netcat port <================\n===>Node: $NomeHost\n"
for i in "${Lista[@]}"; do
      /usr/bin/nc -v -z $i >> /dev/null
      if [ $? == 0 ]; then
      echo -e "$i - ${GREEN}succeeded!${NC}"
            else
      echo -e "$i - ${ORANGE}failed${NC}"
      fi
done
}


NetcatPorts
