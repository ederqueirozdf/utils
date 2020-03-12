# Docker

### Daemon Docker

- Permitir conexão insegura ao registry interno:

        {
          "insecure-registries" : ["172.18.0.7:5001", "172.18.0.7:5003"]
        }
    
- Customizar rede interna docker:    
    
        {
          "bip": "192.168.210.5/24",
          "fixed-cidr": "192.168.210.5/25",
          "mtu": 1500,
          "default-gateway": "192.168.210.1",
          "dns": ["10.1.3.200","10.1.3.202"]
        }


# Jenkins in Docker

    docker run -u root -d -p 8080:8080 -p 50000:50000 -v /opt/jenkins:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkinsci/blueocean
    
### Pipeline script from SCM

- Jenkinsfile (Example)

         pipeline {
          environment {
              dockerRegistry = "http://172.18.0.7:5001"
              ImageName = "example"
              ImageTag= "01"
              dockerImage = ''
          }

        agent any

        stages { 
              stage('Build Image') {
                steps{
                  script {
                    dockerImage = docker.build registry + "/$ImageName:$ImageTag"
                  }
                }
              }
              stage('Deploy Image Registry') {
                steps{
                  script {
                      docker.withRegistry('http://172.18.0.7:5001' , 'docker-registry' ) {
                          docker.build(ImageName)
                              .push(ImageTag)
                    }
                  }
                }
              }
              stage('Clean Workspace') {
                steps{
                 sh "docker rmi -f 172.18.0.7:5001/$ImageName:$ImageTag"
                }
              }
            }
          }
    
# Nexus

### Instalação Ubuntu/Mint

    apt-get install -y openjdk-8-jdk  
    adduser --no-create-home --disabled-password --disabled-login nexus
    mkdir nexus
    cd nexus
    wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz
    tar -xzvf latest-unix.tar.gz
    mv nexus-3.21.1-01 sonatype-work /opt/
    cd /opt/
    chown -R nexus: sonatype-work/
    chown -R nexus: nexus-3.21.1-01/
    cd nexus-3.21.1-01/bin/
    sudo ln -s /opt/nexus-3.21.1-01/bin/nexus /etc/init.d/nexus
    vim /etc/systemd/system/nexus.service
    
                [Unit]
                Description=nexus service
                After=network.target

                [Service]
                Type=forking
                LimitNOFILE=65536
                ExecStart=/opt/nexus-3.21.1-01/bin/nexus start
                ExecStop=/opt/nexus-3.21.1-01/bin/nexus stop
                User=nexus
                Restart=on-abort

                [Install]
                WantedBy=multi-user.target

    
    systemctl daemon-reload
    systemctl enable nexus.service
    systemctl start nexus.service

# Apache Maven

    wget http://mirror.nbtelecom.com.br/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
    tar -zxvf apache-maven-3.6.3-bin.tar.gz
    cd apache-maven-3.6.3/bin
    echo $JAVA_HOME
    vim /etc/profile.d/maven.sh
    sudo ln -s /opt/apache-maven-3.6.3 /opt/maven
    chmod +x /etc/profile.d/maven.sh
    source /etc/profile.d/maven.sh
    mvn --version
    mvn install
    
### Example Settings

            <settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                                  https://maven.apache.org/xsd/settings-1.0.0.xsd">
              <servers>
                <server>
                  <id>nexus</id>
                  <username>admin</username>
                  <password>mma2020</password>
                </server>
                </servers>

          <mirrors>
            <mirror>
              <id>nexus</id>
              <name>Nexus Maven</name>
              <url>http://172.18.0.7:8081/repository/maven-all/</url>
              <mirrorOf>*</mirrorOf>
            </mirror>
          </mirrors>

          <profiles>
            <profile>
                    <id>nexus</id>
                    <repositories>
                       <repository>
                              <id>central</id>
                              <url>http://central</url>
                              <releases><enabled>true</enabled></releases>
                              <snapshots><enabled>true</enabled></snapshots>
                       </repository>
                    </repositories>
              <pluginRepositories>
                       <pluginRepository>
                               <id>central</id>
                               <url>http://central</url>
                               <releases><enabled>true</enabled></releases>
                               <snapshots><enabled>true</enabled></snapshots>
                       </pluginRepository>
              </pluginRepositories>
            </profile>
          </profiles>
          <activeProfiles>
                  <activeProfile>nexus</activeProfile>
          </activeProfiles>
            </settings>

### Example pom.xml

        <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
          <modelVersion>4.0.0</modelVersion>

          <groupId>br.gov.mma</groupId>
          <artifactId>teste</artifactId>
          <version>1.0-SNAPSHOT</version>

          <dependencies>
            <dependency>
              <groupId>junit</groupId>
              <artifactId>junit</artifactId>
              <version>4.12</version>
              <scope>test</scope>
            </dependency>
            </dependencies>
          <distributionManagement>

            <repository>
            <id>nexus</id>
            <name>maven-releases</name>
            <url>http://localhost:8081/repository/maven-releases/</url>
            </repository>

            <snapshotRepository>
            <id>nexus</id>
            <name>maven-snapshots</name>
            <url>http://localhost:8081/repository/maven-snapshots/</url>
            </snapshotRepository>

           </distributionManagement>
        </project>


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
