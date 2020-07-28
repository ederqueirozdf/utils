<h1 align="center">Upstream NGINX 👋</h1>

## Author
👤 **Eder Queiroz**
* Github: [@ederqueirozdf](https://github.com/ederqueirozdf)

## 🤝 Contribuições são bem vindas
Linux ❤️
<hr>

# Nginx

- Configurações para balanceamento nginx com certificado ssl habilitado.
- SSL OffLoading Nginx to Webservice apache hosts com aplicação sei

~ nginx version: nginx/1.15.8 ~

# Upstream (Balanceamento NGINX)

    upstream homolog-sei {
            ip_hash;
            server 10.1.0.1;
            server 10.1.0.2;
            server 10.1.0.3;
            keepalive 32;
        }

        server {
            listen 80;
            listen [::]:80;
            server_name homolog-sei.com.br;

    #file-size

            client_max_body_size 6144M;

    #ssl
            listen 443 ssl;
            listen [::]:443 ssl;
            ssl_certificate     /etc/nginx/ssl/fullchain1.pem;
            ssl_certificate_key /etc/nginx/ssl/privkey1.pem;
            ssl_ciphers                 ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256;
            ssl_protocols TLSv1.2 TLSv1.3; # Requires nginx >= 1.13.0 else use TLSv1.2
            ssl_prefer_server_ciphers on;
            ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
            ssl_session_timeout  10m;
            ssl_session_cache shared:SSL:10m;
            ssl_session_tickets off; # Requires nginx >= 1.5.9
            ssl_stapling on; # Requires nginx >= 1.3.7
            ssl_stapling_verify on; # Requires nginx => 1.3.7
            resolver_timeout 5s;
    
    #cabeçalhos protocol http
            
            add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
            add_header X-Frame-Options DENY;
            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection "1; mode=block";
    #logs
            access_log      /var/log/nginx/homolog-sei.access.log main;
            error_log       /var/log/nginx/homolog-sei.error.log warn;

    # force https-redirects
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
    }

            location / {
                    proxy_next_upstream     error timeout invalid_header http_500;
                    proxy_connect_timeout   3;
                    proxy_pass              http://homolog-sei;
                    }
     }



