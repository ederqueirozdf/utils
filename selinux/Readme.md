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

# Joomla

     setsebool -P httpd_unified on

    find -type d -exec chmod 755 {} \;
    find -type f -exec chmod 644 {} \;

    # chcon -R -t httpd_sys_content_t joomla
    # chcon -Rv -t httpd_cache_t          joomla/administrator/cache
    # chcon -Rv -t httpd_cache_t          joomla/cache
    # chcon -Rv -t httpd_sys_log_t        joomla/logs
    # chcon -Rv -t httpd_sys_rw_content_t joomla/tmp
    
### Opção 2:

     semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html(/.*)?"
