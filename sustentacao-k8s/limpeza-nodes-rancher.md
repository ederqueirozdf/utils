# Limpeza de nodes kubernetes do Rancher

O processo de limpeza dos nodes se baseia nos seguintes passos:

- Remover todos os containers, imagens e volumes do docker; (DRAIN)
- Parar o docker no node;
- Desmontar os volumes relacionados aos pods e containers;
- Remover os diretórios e arquivos relacionados ao kubernetes;
- Reiniciar a máquina.

A [documentação oficial do Rancher](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/cleaning-cluster-nodes/) traz essas informações sempre atualizadas.

## DRAIN

`kubectl drain <<node_name>> --force=true --grace-period=0 --ignore-daemonsets`

Faça login no node e execute os comandos abaixo:

## Nodes CentOS

```shell
sudo -i

docker rm -f $(docker ps -qa)
docker rmi -f $(docker images -q)
docker volume rm $(docker volume ls -q)

systemctl stop docker

for mount in $(mount | grep tmpfs | grep '/var/lib/kubelet' | awk '{ print $3 }') /var/lib/kubelet /var/lib/rancher; do umount $mount; done

rm -rf /etc/ceph \
       /etc/cni \
       /etc/kubernetes \
       /opt/cni \
       /opt/rke \
       /run/secrets/kubernetes.io \
       /run/calico \
       /run/flannel \
       /var/lib/calico \
       /var/lib/etcd \
       /var/lib/cni \
       /var/lib/kubelet \
       /var/lib/rancher/rke/log \
       /var/log/containers \
       /var/log/pods \
       /var/run/calico \
       /var/lib/docker/*
```

**Reiniciar a máquina após a limpeza ser concluída com sucesso.**
  
  reboot

Faça o login novamente no node se necessário e verifique se o node não possui nenhuma imagem no docker ou container em execução.

```shell
docker ps -a
docker images -a
docker volume ls
```
