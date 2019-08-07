
# Apache-Utils 
### Requisições para teste de balanceamento

Instalação do apache-utils

    yum install httpd-utils

Schedule com 800.000 conexões

    ab -n 800000 -c 4 http://url
