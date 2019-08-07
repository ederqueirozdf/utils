# Script

- Script para build/construção de imagem docker com código fonte em repositório git.


        pipeline {
        environment {
            registry = "registry.dominio.com.br"
            dockerRegistry = "registry.dominio.com.br"
            registryCredential = 'usr-registry-credential'
            ImageName = "nome-da-imagem-docker"
            ImageTag= "tag-da-imagem-docker"
            dockerImage = ''
            gitRepositoryUrl = "http://url-repositorio.git"
            gitCredential = "usr-git-credential"
            gitBranch = "nome-da-branch-git"
        }

      agent any
      
      stages {
        stage('Checkout Código-fonte') {
            steps {
              git([
                  poll: true,
                  credentialsId: gitCredential,
                  url: gitRepositoryUrl,
                  branch: gitBranch
              ])

          }
        }
        
            stage('Building image') {
              steps{
                script {
                  dockerImage = docker.build registry + "/$ImageName:$ImageTag"
                }
              }
            }
            stage('Deploy Image') {
              steps{
                script {
                    docker.withRegistry( 'https://$dockerRegistry/', 'docker-registry' ) {
                        docker.build(ImageName)
                            .push(ImageTag)
                  }
                }
              }
            }
            stage('Remove Unused docker image') {
              steps{
                sh "docker rmi $registry/$ImageName:$ImageTag"
              }
            }
          }
        }



# Limpeza de images Docker
### Usamos também os famosos comandos:

                sudo docker rm -v $(sudo docker ps -a -q -f status=exited)

                sudo docker rmi -f $(sudo docker images -f "dangling=true" -q)

                docker volume ls -qf dangling=true | xargs -r docker volume rm
