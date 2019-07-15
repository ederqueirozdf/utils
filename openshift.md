# Uteis Openshift

### Gerar CA openshift para proxy reverso externo:

    export CA=/etc/origin/master

    oc adm ca create-server-cert --signer-cert=$CA/ca.crt --signer-key=$CA/ca.key --signer-serial=$CA/ca.serial.txt --hostnames='*.apps.dominio.com.br' --cert=cloudapps.crt --key=cloudapps.key
