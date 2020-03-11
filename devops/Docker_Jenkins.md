# Jenkins in Docker

    docker run -u root -d -p 8080:8080 -p 50000:50000 -v /opt/jenkins:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkinsci/blueocean


# Configurar plugin Docker Jenkins

    abrir o Jenkins
    menu Manage Jenkins
    menu Configure System
    na seção Cloud
        clicar em Add a new cloud > Docker > preencher os campos
        Name: docker cloud
        Docker Host URI: unix:///var/run/docker.sock ou tcp://IP-MAQUINA-DOCKER:2375
        clicar em Test Connection e se tudo ok deve exibir a versão do docker
        Enabled: check
        Container Cap: 5
        clicar em Docker Agent templates...
        clicar em Add Docker Template
        Labels: docker-slave
        Enabled: check
        Docker Image: jenkins/ssh-slave
        clicar em Container settings...
        Remote Filing System Root: /home/jenkins
        Usage: Only build jobs with label expressions matching this node
        Connect method: Connect with SSH
        SSH Key: Inject SSH Key
        User: jenkins
        Pull strategy: Pull once and update latest
    clicar em Save
