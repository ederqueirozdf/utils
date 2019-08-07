# Infraestrutura - Úteis

# Integração Active Directory Realmd LINUX

A integração dos servidores Linux com o Active Directory será realizada com o REALMD. Este pacote configura os serviços subjacentes do sistema Linux, como SSSD ou Winbind, para se conectar ao domínio.

#### Procedimento

    #yum install realmd

    #yum install  sssd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools 

    #realm join --user="NOME-USUARIO" "DOMINIO"


### Configuração do arquivo SSSD


	#vim /etc/sssd.conf
	use_fully_qualified_names = False


### Configuração do arquivo sshd_config


        #vim /etc/ssh/sshd_config
        AllowGroups "NOME-DO-GRUPO-AD"


### Reinicialização dos serviços

	#systemctl restart sshd
	#systemctl restart sssd



# F5 BigIp

### Redirecionamento HTTPS

    tcl:https://[getfield [HTTP::host] : 1][HTTP::uri]
 

### Cabeçalho - HeaderForwarded

    X-Real-IP tcl:[IP::client_addr]
    X-Forwarded-For tcl:[IP::client_addr]
    X-Forwarded-Proto https
    X-Forwarded-Server tcl:[getfield [HTTP::host] : 1]
    X-Forwarded-Host tcl:[HTTP::host]

