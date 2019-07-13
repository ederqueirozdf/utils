# JenkinsX

JX usa 4 blocos de construção principais:

**Jenkins X** - É uma plataforma autônoma (não apenas uma extensão do Jenkins), que coordena todos os componentes abaixo. Fornece uma camada de abstração que facilita a comunicação e o gerenciamento desses componentes do sistema. As abstrações do Jenkins X utilizam explicitamente os termos do DevOps (aplicação, ambiente, promoção), convergindo assim terminologias de diferentes tecnologias. Vem com uma CLI para gerenciar a plataforma (jx).

**Git** - Armazena todo o código e configurações, incluindo a configuração dos ambientes (infraestrutura da aplicação). Serve como fonte de verdade para tudo. O Jenkins X gerencia repositórios Git remotos e segue os princípios do GitOps.

**Kubernetes** - Gerencia contêineres em escala, provendo ambientes de trabalho de desenvolvimento e operação dos aplicativos. Os recursos dentro do k8s são gerenciados com a ajuda do Helm e organizados no Helm Charts por padrão. Jenkins X foi projetado para instalar todos os módulos no cluster k8s. Também é possível criar um cluster k8s com os seguintes provedores de nuvem suportados:

- AWS
- GKE
- Azure
- Minikube
- OpenShift (planejado)
- EKS (planejado)

**Jenkins** - Solução de código aberto / CD de código aberto. O Jenkins X faz uso do Jenkins para criar e executar pipelines de CI / CD.

### Abstrações Jenkins X:

Como diferentes componentes do sistema utilizam um vocabulário diferente, o Jenkins X tenta se espalhar por todos os domínios com sua própria camada de abstração. E as entidades mais importantes incluem os seguintes itens:

**Enviroment** - é um contêiner no qual os Aplicativos são implantados. Por padrão, os ambientes ' staging' e ' production' são criados durante a instalação do JX no k8s.
**Application** - é uma representação de um aplicativo em desenvolvimento.

*A próxima figura mostra como partes do sistema JX estão conectadas:*

<img src="https://i.imgur.com/oniXq7h.png">


### Kubernetes e Helm

O Kubernetes hospeda todos os serviços implementados pelo JX, incluindo os administrativos *(Jenkins, Chartmuseum, Monocular etc)*. A implantação dos serviços (ou aplicativos) é coordenada via **Helm**. Gráficos de Helm permitem o compartilhamento de Templates de aplicativos e facilita o controle de versões. O Helm também cuida dos casos de upgrade e rollback, o que o torna bastante útil.

Cada Helm Chart possui um diretório que contém os seguintes arquivos:

	**Chart.yaml**: contém os metadados do gráfico, como nome, versão, descrição, etc.
	**requirements.yaml**: descreve as dependências do Chart em outros gráficos. Cada dependência consiste no nome do gráfico, alias, versão e repositório dessa dependência.
	**templates / directory**: contém arquivos de templates escritos em linguagem Go. Templates descrevem quais contêineres usar, seus fatores de replicação, descrições de serviços, etc.
	**values.yaml** : contém valores padrão para templates.
	