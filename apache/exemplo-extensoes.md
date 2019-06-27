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