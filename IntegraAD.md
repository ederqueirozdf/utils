### Integração Active Directory - REALMD

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

