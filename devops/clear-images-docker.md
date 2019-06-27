# Usamos também os famosos comandos:

sudo docker rm -v $(sudo docker ps -a -q -f status=exited)

sudo docker rmi -f  $(sudo docker images -f "dangling=true" -q)

docker volume ls -qf dangling=true | xargs -r docker volume rm
