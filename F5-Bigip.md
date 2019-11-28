# F5 BigIp

### Redirecionamento HTTPS

    tcl:https://[getfield [HTTP::host] : 1][HTTP::uri]
 

### Cabeçalho - HeaderForwarded

    X-Real-IP tcl:[IP::client_addr]
    X-Forwarded-For tcl:[IP::client_addr]
    X-Forwarded-Proto https
    X-Forwarded-Server tcl:[getfield [HTTP::host] : 1]
    X-Forwarded-Host tcl:[HTTP::host]


### Replace URI $path Policy

tcl:[string map {"/path1/" "/"} [HTTP::uri]]
