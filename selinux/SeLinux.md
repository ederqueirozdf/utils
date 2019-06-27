# SELINUX

Comandos úteis

#### Configuração do SELINUX para permissão de porta customizada (SSH) 

*Port 2525*

PermitRootLogin no

    # yum install policycoreutils-python
    # semanage port -a -t ssh_port_t -p tcp 2525
    # semanage port -l | grep ssh
    # firewall-cmd --permanent --zone=public --add-port=2525/tcp
    # firewall-cmd --reload

