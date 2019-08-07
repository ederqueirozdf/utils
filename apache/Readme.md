
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
        
# Vhost Apache


<VirtualHost *:80>

        ServerAdmin webmaster@dominio.com.br
        DocumentRoot /dados/dominio
        ServerName dominio.com.br
        CustomLog /dados/log/dominio.access.log combined
        ErrorLog /dados/log/dominio.error.log
        LogLevel warn
        <Directory /dados/dominio/>
                Options -Indexes
                AllowOverride all
                Require all granted

        </Directory>

</VirtualHost>
