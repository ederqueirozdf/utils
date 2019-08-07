
# Apache-Utils 
### Requisições para teste de balanceamento

Instalação do apache-utils

    yum install httpd-utils

Schedule com 800.000 conexões

    ab -n 800000 -c 4 http://url

# Bloqueio - Extensões Apache

Abaixo exemplo de bloqueio de acesso as extensões ".map" no workdir da aplicação configurada no apache.

        <VirtualHost *:80>
                ServerAdmin webmaster@localhost
                DocumentRoot /opt/www/html
        <Directory /opt/www/html/>
                                <FilesMatch "\.(map)$">
                                        Order deny,allow
                                        Deny from all
                                </FilesMatch>
                        Options FollowSymLinks MultiViews
                        AllowOverride None
                        Order allow,deny
                        allow from all

                </Directory>
        </VirtualHost>
