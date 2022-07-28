O node apresenta Pods em Container Creating e nos eventos do pod aparecem erros 
com mensagens com parte do texto: 
> __networkPlugin cni failed to set up pod__
> ou
> __sandbox__

```
#!/bin/bash

logFile="/tmp/ips-liberados.txt"
touch ${logFile}
#Realizando operacoes sobre nodes (prune, apagando ips)
echo "=======================================" >> ${logFile}
echo "$(date)" >> ${logFile}
echo "Executando container prune..." >> ${logFile}
sudo  docker container prune -f >/dev/null 2>&1

_ipsDir="/var/lib/cni/networks/k8s-pod-network"
cd ${_ipsDir}
echo "$(date)" >> ${logFile}
echo "Realizando limpeza de IPs no diretório ${_ipsDir}..." >> ${logFile}
for hash in $(sudo tail -n +1 * | sudo grep -E '^[A-Za-z0-9]{64}' | cut -c 1-8); do if [ -z $(sudo docker ps -a | sudo grep $hash | awk '{print $1}') ]; then sudo grep -ilr $hash ./; fi; done | xargs sudo rm -v 2>&1 >> ${logFile} 2>&1

exit 0
```
