# SELINUX

Comandos úteis

#### Configuração do SELINUX para permissão de porta customizada (SSH) 

*Port 1234*

PermitRootLogin no

    # yum install policycoreutils-python
    # semanage port -a -t ssh_port_t -p tcp 1234
    # semanage port -l | grep ssh
    # firewall-cmd --permanent --zone=public --add-port=1234/tcp
    # firewall-cmd --reload

