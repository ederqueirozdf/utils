# Uteis Openshift

### Gerar CA openshift para proxy reverso externo:

    export CA=/etc/origin/master

    oc adm ca create-server-cert --signer-cert=$CA/ca.crt --signer-key=$CA/ca.key --signer-serial=$CA/ca.serial.txt --hostnames='*.apps.dominio.com.br' --cert=cloudapps.crt --key=cloudapps.key

### Configuração de plugin para expansão de volumes

    # vim /etc/orgin/master/master-config.yaml

**Bloco de configuração para habilitação do plugin PersistentVolumeClaimResize**

    admissionConfig:                                                                                                        
      pluginConfig:                                                                                                         
        PersistentVolumeClaimResize:                                                                                        
          configuration:                                                                                                    
            apiVersion: v1                                                                                                  
            disable: true                                                                                                   
            kind: DefaultAdmissionConfig

**Após alteração do arquivo de configuração dos nodes masters, reiniciar os serviços: **

    # master-restart controllers
    # master-restart api
