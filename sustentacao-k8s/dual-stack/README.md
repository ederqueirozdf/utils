# IPv4/IPv6 dual-stack

### Introdução

A configuração dual-stack permite a alocação de endereços IPv4 e IPv6 para **pods** e **serviços** no cluster kubernetes. Os seguintes pré-requisitos são necessários para habilitar dual-stack:

- **Pré-Requisitos**
  - Kubernetes 1.16 ou posterior 
  - Plug-in de rede compatível com dual-stack. Na estrutura de cluster k8s BB, utilizamos o [(**Calico**)](https://docs.projectcalico.org/getting-started/kubernetes/).
  
# Configuração

## Configurando o cluster

- Este documento presume que você já tenha um cluster kubernetes em operação.
  
### IPv6: Configurando os nós do cluster

Por padrão distribuições linux mais recentes possuem o encaminhamento de IP desativado. Será preciso habilitar o encaminhamento IPv6, uma vez que precisaremos aceitar pacotes de rede de entrada em uma interface ipv6.

Você pode verificar se o encaminhamento de IP está habilitado. Acessando o host(nó) do cluster execute o seguinte comando:

    sysctl net.ipv6.conf.all.forwarding

> Nota: Se o valor do resultado do comando acima é = `0`, o encaminhamento de IP está desabilitado. Se for = `1` está habilitado.

Para habilitar imediatamente execute o comando:

    sysctl -w net.ipv6.conf.all.forwarding=1

Esta configuração é válida temporariamente (até que o host seja reiniciado).

Para realizar a configuração definitiva no cluster siga os passos abaixo:

- Sistema Operacional: **RancherOS**

Crie um arquivo com o seguinte conteúdo:

    $ vi fwdipv6.yml
>
    #cloud-config
    rancher:
    sysctl:
        net.ipv6.conf.all.forwarding: 1

Em seguida, utilize o comando abaixo para mesclar as configurações em seu sistema existente. 

    sudo ros config merge -i fwdipv6.yml

**Referência:**
- https://rancher.com/docs/os/v1.x/en/configuration/sysctl/


### IPv6: Configurando o CNI Dual-Stack (Calico)

À partir da versão 3.11 o calico oferece suporte total para configuração Dual-stack no Kubernetes - que permite que cada pod do Kubernetes obtenha um endereço IPv6, bem como um endereço IPv4.

- **Pré-Requisitos do Calico**
  - Kubernetes 1.16 ou posterior
  - Calico IPAM

Na estrutura k8s-aplic, navegue até o release do calico e edite o arquivo `calico-config.yaml` para habilitar a alocação de endereços IPv4 e IPv6. Adicionando os parametros assign_ipv4 e assign_ipv6 com o valor `true`. 

| Variavel    | Valor |
| ----------- | ----- |
| assign_ipv4 | true  |
| assign_ipv6 | true  |


> Nota: Para que fosse possível fazer as edições nos manifestos foi necessário descompactar o charts do calico.


          cni_network_config: |-
          
          ...

          "ipam": {
            "type": "calico-ipam",
            "assign_ipv4" : "true",
            "assign_ipv6" : "true"
          },

          ...

- [ Clique aqui para acessar um exemplo do arquivo calico-config.yaml](calico-config.yaml)

Também é preciso configurar o suporte IPv6 através de variáveis de ambiente para os containers do calico. Edite o arquivo `calico-node.yaml` e configure as seguintes variáveis de


| Variavel          | Valor      |
| ----------------- | ---------- |
| IP6               | autodetect |
| FELIX_IPV6SUPPORT | true       |
 
 As seguintes linhas foram incluídas no arquivo:

    containers:
      env:
    ...

      - name: IP6
      value: {{ default "none" .Values.calicoNode.env.IP6 | quote  }}     
      
    ...

      - name: FELIX_IPV6SUPPORT
          value: {{ default "false" .Values.calicoNode.env.FELIX_IPV6SUPPORT | quote }}

    ...

Ainda na configuração do `calico-node`, é preciso configurar o pool de IP em IPv6. Para habilitar está configuração, é preciso configurar a seguinte variável de ambiente:

| Variavel             | Valor              |
| -------------------- | ------------------ |
| CALICO_IPV6POOL_CIDR | "2001:0:0:2::/104" |

As seguintes linhas foram incluídas no arquivo `calico-node.yaml`.

        {{- if .Values.calicoNode.env.CALICO_IPV6POOL_CIDR }}
        - name: CALICO_IPV6POOL_CIDR
            value: {{ .Values.calicoNode.env.CALICO_IPV6POOL_CIDR }}
        {{- end }}

- [ Clique aqui para acessar um exemplo do arquivo calico-config.yaml](calico-node.yaml)

Finalizada as configurações nos manifestos acima declarados, informe no arquivo `values.yaml ` do charts os valores das variáveis e condições configuradas:

Nas variáveis globais deve ser informado as seguintes variaveis:

    env:
      ...
      
    IP6: "autodetect"
    # Auto-detect the BGP IP address.

    CALICO_IPV6POOL_CIDR: "2001:0:0:2::/104" 
    #IPv6 pool to create on startup if none exists

    FELIX_IPV6SUPPORT: "true"
    # Enable/disable IPv6 on Kubernetes.

      ...

    extraEnv:
      CALICO_IPV6POOL_NAT_OUTGOING: "true"

      ...

> Importante:  Nas configurações realizadas, observamos que a replicação pode ser mais demorada do que esperado. Sendo assim, você pode precisar forçar a configuração. Confira a seção [**TShoot**](#TShoot) para verificar as ações realizadas.

- [ Clique aqui para acessar um exemplo do arquivo values.yaml referente ao charts do calico.](values-calico.yaml)

- Referência:
  - https://docs.projectcalico.org/networking/ipv6#enable-dual-stack
- Links de apoio:
  - https://www.projectcalico.org/enable-ipv6-on-kubernetes-with-project-calico/
  - https://www.projectcalico.org/dual-stack-operation-with-calico-on-kubernetes/
  - https://docs.projectcalico.org/networking/ipv6-control-plane
  - https://docs.projectcalico.org/reference/node/configuration

### IPv6: Configurando o cluster Kubernetes (Rancher)

A configuração dual-stack no cluster kubernetes é habilitada através de features nos principais componentes do cluster. De acordo com a documentação as features da versão 1.18 são as seguintes:

- **KUBE-API**
  - `--feature-gates="IPv6DualStack=true"`

- **KUBE-CONTROLLER**
  - `--feature-gates="IPv6DualStack=true"`
  - `--cluster-cidr=IPv4 CIDR,IPv6 CIDR`
  - `--service-cluster-ip-range=IPv4 CIDR,IPv6 CIDR`
  - `--node-cidr-mask-size-ipv4`
  - `--node-cidr-mask-size-ipv6`

- **KUBELET**
  - `--feature-gates="IPv6DualStack=true"`

- **KUBE-PROXY**
  - `--feature-gates="IPv6DualStack=true"`
  - `--cluster-cidr=<IPv4 CIDR>,<IPv6 CIDR>`

> É preciso que o kube-proxy esteja configurado no modo IPVS.

O provisionamento da stack de infraestrutura para clusters Kubernetes no ambiente BBCloud são criados a partir de configurações declarativas de infraestrutura como código baseado em [Gitops.](https://www.gitops.tech/) As configurações dos clusters RKE são declaradas através dos manifestos denominados **"Rancher-aplic"** na estrutura "k8s-aplic". O "k8s-aplic" configura as aplicações que serão provisionadas no cluster através do argoCD baseada no conceito "Apps-of-apps". Portanto, as configurações das features listadas acima deverão ser declaradas no arquivo `values.yaml` da aplicação 05-rancher-aplic referente ao seu cluster:

Estrutura rancher-aplic:

    .
    ├── 00-bootstrap
    │   └── 05-rancher-aplic
    │       ├── charts
    │       │   └── rancher-aplic-0.1.0.tgz
    │       ├── Chart.yaml
    │       ├── requirements.lock
    │       └── values.yaml

No arquivo `values.yaml` estarão declaradas todas as configurações do cluster kubernetes, bem como do rancher (RKE).

São basicamente dois blocos de configurações: `rancher-aplic` e `cluster`.

Dentro do bloco `cluster` aplicaremos as flags nos componentes do cluster kubernetes conforme documentação.

- kubeApi

      serviceClusterIpRange: "3.3.0.0/16"
      extraArgs:
        service-cluster-ip-range: "3.3.0.0/16,2001:0:0:3::/112"
        feature-gates: "IPv6DualStack=true"

Apesar da documentação orientar apenas a flag `feature-gates` no componente **kubeApi**, houve a necessidade de declarar também a flag `service-cluster-ip-range` por conta do suporte dual-stack no Rancher conforme comentários no link da issue abaixo onde foi identificado problema na função **GetKubernetesServiceIP**.

- Issue RKE Dual-Stack: 
  - https://github.com/rancher/rke/issues/1902

> Com a flag `service-cluster-ip-range` no extraArgs, a função GetKubernetesServiceIP validará o IP do serviço normalmente, e o service-cluster-ip-range em extra_args substituirá a sinalização --service-cluster-ip-range no componente kube-apiserver, para que o cluster tenha todas as configurações necessárias para executar o cluster em dual-stack.

- kubeController

      clusterCidr: "3.2.0.0/16,2001:0:0:2::/104"
      extraArgs:
        feature-gates: "IPv6DualStack=true"

- kubelet

        extraArgs:
          feature-gates: "IPv6DualStack=true"

- kube-proxy
  
      kubeproxy:
        clusterCidr: "3.2.0.0/16,2001:0:0:2::/104"
        extraArgs:
          feature-gates: "IPv6DualStack=true"       
          proxy-mode: "ipvs"

- [ Clique aqui para acessar um exemplo do arquivo values.yaml referente as configurações do rancher-aplic.](values-rancher-aplic.yaml)

Após a configuração das flags, execute o sync do cluster no argoCD.

**Referência:**
- https://v1-18.docs.kubernetes.io/docs/concepts/services-networking/dual-stack/

# Validação

Para validação configuramos um manifesto para criação de um serviço ipv6 e de um container com uma app de exemplo e basicamente seguimos as validações do link de referência.

Manifesto utilizado para configuração do pod com aplicação hello-kubernetes:

- hello-k8s.yaml

      apiVersion: v1
      kind: Pod
      metadata:
        name: hello-k8s
        namespace: default
        labels:
          app: hello-k8s
      spec:
        containers:
        - name: hello-k8s
          image: atf.intranet.bb.com.br:5001/paulbouwer/hello-kubernetes:1.9

Criando o pod:

    kubectl create -f hello-k8s.yaml
    pod/hello-k8s created

Validando endereço do pod hello-k8s:

    kubectl get pods hello-k8s -n default -o go-template --template='{{range .status.podIPs}}{{printf "%s\n" .ip}}{{end}}'

    3.2.184.119
    2001::2:0:0:17:c2fb

Manifesto utilizado para configuração do serviço em ipv6:

- svc-ipv6.yaml

      apiVersion: v1
      kind: Service
      metadata:
        namespace: default
        name: svc-hellok8s
        labels:
          app: hello-k8s
      spec:
        ipFamily: "IPv6"
        type: ClusterIP
        selector:
          app: hello-k8s
        ports:
          - port: 80
            protocol: TCP
            targetPort: 8080

Criando o serviço:

    kubectl create -f svc-ipv6.yaml
    service/svc-hellok8s created

Validando endereço do serviço ipv6:

    kubectl get svc

    NAME           TYPE        CLUSTER-IP         EXTERNAL-IP   PORT(S)   AGE
    kubernetes     ClusterIP   3.3.0.1            <none>        443/TCP   9d
    svc-hellok8s   ClusterIP   2001:0:0:3::4630   <none>        80/TCP    4m37s

Também criamos um pod de tshoot para validar comunicação entre os pods, bem como acesso ao serviço ipv6 configurado. Abaixo segue o manifesto yaml utilizado:

Manifesto utilizado para criação do pod de tshoot:

- pod-utils.yaml
                                                      
      apiVersion: v1
      kind: Pod
      metadata:
        name: netshoot
        namespace: default
      spec:
        containers:
        - name: netshoot
          image: atf.intranet.bb.com.br:5001/nicolaka/netshoot:latest
          command:
            - sleep
            - "3600"

Criando o pod:

    kubectl create -f pod-utils.yaml
    pod/netshoot created

Capturando o ipv6 do pod:

    kubectl get pods hello-k8s -n default -o go-template --template='{{range .status.podIPs}}{{printf "%s\n" .ip}}{{end}}'
    3.2.184.119
    2001::2:0:0:17:c2fb

Testando comunicação icmp:

    kubectl exec -it netshoot -- ping6 2001::2:0:0:17:c2fb


    PING 2001::2:0:0:17:c2fb(2001::2:0:0:17:c2fb) 56 data bytes
    64 bytes from 2001::2:0:0:17:c2fb: icmp_seq=1 ttl=63 time=0.572 ms
    64 bytes from 2001::2:0:0:17:c2fb: icmp_seq=2 ttl=63 time=0.246 ms
    64 bytes from 2001::2:0:0:17:c2fb: icmp_seq=3 ttl=63 time=0.230 ms

Testando comunicação de acesso à aplicação hello-k8s em ipv6:

Capturando ipv6 do serviço hello-k8s:

    kubectl get svc -l app=hello-k8s

    NAME           TYPE        CLUSTER-IP         EXTERNAL-IP   PORT(S)   AGE
    svc-hellok8s   ClusterIP   2001:0:0:3::4630   <none>        80/TCP    18m

Acessando serviço em ipv6:

    kubectl exec -it netshoot -- curl 'http://[2001:0:0:3::4630]'


        <!DOCTYPE html>
    <html>
    <head>
        <title>Hello Kubernetes!</title>
        <link rel="stylesheet" type="text/css" href="/css/main.css">
        <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Ubuntu:300" >
    </head>
    <body>

      <div class="main">
        <img src="/images/kubernetes.png"/>
        <div class="content">
          <div id="message">
      Hello world!
    </div>
    <div id="info">
      <table>
        <tr>
          <th>pod:</th>
          <td>hello-k8s</td>
        </tr>
        <tr>
          <th>node:</th>
          <td>Linux (4.14.138-rancher)</td>
        </tr>
      </table>

    </div>
        </div>
      </div>

    </body>
    </html>%  

**Referência:**
- https://v1-18.docs.kubernetes.io/docs/tasks/network/validate-dual-stack/  
- https://v1-18.docs.kubernetes.io/docs/concepts/services-networking/dual-stack/

# Tshoot

### Configurações de ipPool Calico

Calico usa pools de IP para configurar como os endereços são alocados aos pods e como a rede funciona para determinados conjuntos de endereços.

Para identificar o ipPools no cluster:

    kubectl get ipPool

    NAME                  AGE
    default-ipv4-ippool   9d
    default-ipv6-ippool   3d22h


Para verificar se as configurações foram aplicadas corretamente, verifique o describe do ipPool e observe se o Cidr corresponde ao informando no arquivo de values.yaml do calico.

    kubectl describe ipPool default-ipv6-ippool

    Spec:
      Block Size:     122
      Cidr:           2001:0:0:2::/104
      Ipip Mode:      Never
      Nat Outgoing:   true
      Node Selector:  all()
      Vxlan Mode:     Never
    Events:           <none>

Caso o Cidr seja diferente do valor declarado no arquivo de configuração, você pode forçar o redeploy dos pods para recriar o arquivo de ipPool.

Primeiro, faça a deleção do ipPool:

    kubectl delete ipPool default-ipv6-ippool

Em seguida, faça a deleção dos pods calico em execução.
Para visualizar os pods:

    kubectl get pods -n kube-system

    NAME                                       READY   STATUS      RESTARTS   AGE
    calico-kube-controllers-6ccfff4948-7hf2m   1/1     Running     7          3d17h
    calico-node-9xv67                          1/1     Running     6          3d17h
    calico-node-zn4cl                          1/1     Running     4          3d17h
    coredns-autoscaler-6d4669f94-4msgl         1/1     Running     1          3d17h
    coredns-ffd79f768-v9blv                    1/1     Running     1          3d17h
    metrics-server-6987c87c8b-rxpjx            1/1     Running     6          9d
    rke-metrics-addon-deploy-job-9dz6z         0/1     Completed   0          9d

Para deletar os pods:

    for i in `kubectl get pods -n kube-system |awk '/^calico/ {print $1}'`; do kubectl delete pod $i; done
  
O comando acima é para facilitar a exclusão dos pods referentes ao calico no namespace kube-system. Para que não seja preciso deletar pod por pod.

Após a exclusão, verifique novamente o **ipPool** e observe se o **Cidr** aplicou a rede declarada corretamente.

### Configurações de NAT IPv6 Calico

Para comunicação externa dos pods em IPv6 é necessário verificar o status das configurações de NAT no ipPool ipv6.

A configuração de `CALICO_IPV6POOL_NAT_OUTGOING` habilitada no **ExtraArgs** do arquivo de **values.yaml** do calico deve habilitar esta configuração.

- `CALICO_IPV6POOL_NAT_OUTGOING:` Controls NAT Outgoing for the IPv6 Pool created at start up. [Default: false]

Você pode verificar os ipPools também com o comando:

    kubectl get ipp

    NAME                  AGE
    default-ipv4-ippool   9d
    default-ipv6-ippool   3d23h

Verifique a configuração da flag `Nat Outgoing` no ipPool ipv6:

    kubectl describe ippools.crd.projectcalico.org default-ipv6-ippool

Observe no spec, se o valor de `Nat Outgoing` é `true`

    ...

    Spec:
      Block Size:     122
      Cidr:           2001:0:0:2::/104
      Ipip Mode:      Never
      Nat Outgoing:   true
      Node Selector:  all()
      Vxlan Mode:     Never
    Events:           <none>
