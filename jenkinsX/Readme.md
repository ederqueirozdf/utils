# JenkinsX

 JX usa 4 blocos de construção principais:

Jenkins X - É uma plataforma autônoma (não apenas uma extensão do Jenkins), que coordena todos os componentes abaixo. Fornece uma camada de abstração que facilita a comunicação e o gerenciamento desses componentes do sistema. As abstrações do Jenkins X utilizam explicitamente os termos do DevOps (aplicação, ambiente, promoção), convergindo assim terminologias de diferentes tecnologias. Vem com uma CLI para gerenciar a plataforma (jx).

Git - Armazena todo o código e configurações, incluindo a configuração dos ambientes (infraestrutura da aplicação). Serve como fonte de verdade para tudo. O Jenkins X gerencia repositórios Git remotos e segue os princípios do GitOps.

Kubernetes - Gerencia contêineres em escala, provendo ambientes de trabalho de desenvolvimento e operação dos aplicativos. Os recursos dentro do k8s são gerenciados com a ajuda do Helm e organizados no Helm Charts por padrão. Jenkins X foi projetado para instalar todos os módulos no cluster k8s. Também é possível criar um cluster k8s com os seguintes provedores de nuvem suportados:

- AWS
- GKE
- Azure
- Minikube
- OpenShift (planejado)
- EKS (planejado)

Jenkins - Solução de código aberto / CD de código aberto. O Jenkins X faz uso do Jenkins para criar e executar pipelines de CI / CD.

Abstrações Jenkins X:

Como diferentes componentes do sistema utilizam um vocabulário diferente, o Jenkins X tenta se espalhar por todos os domínios com sua própria camada de abstração. E as entidades mais importantes incluem os seguintes itens:

Enviroment - é um contêiner no qual os Aplicativos são implantados. Por padrão, os ambientes ' staging' e ' production' são criados durante a instalação do JX no k8s.
Application - é uma representação de um aplicativo em desenvolvimento.

A próxima figura mostra como partes do sistema JX estão conectadas:

<img src="https://i.imgur.com/oniXq7h.png">
