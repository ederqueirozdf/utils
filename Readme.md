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

**Chart.yaml:** contém os metadados do gráfico, como nome, versão, descrição, etc.
**requirements.yaml:** descreve as dependências do Chart em outros gráficos. Cada dependência consiste no nome do gráfico, alias, versão e repositório dessa dependência.
**templates / directory:** contém arquivos de templates escritos em linguagem Go. Templates descrevem quais contêineres usar, seus fatores de replicação, descrições de serviços, etc.
**values.yaml:** contém valores padrão para templates.

### Jenkins

A instância do jenkins é implatada no cluster do Kubernetes como parte da instalação do **JenkinsX**, executado master/agent em modo distribuído, ou seja, há sempre um processo "master" em execução, atendendo as solicitações ao console do jenkins e distribuindo a carga para vários "agents". Sendo assim, é possível processar várias execuçoes de pipelines concorrentemente e distribuir uniformemente as cargas de trabalho. O master e cada um dos agents são deployados como pods separados no Kubernetes.

O pipeline do Jenkins são descritos em um arquivo de configuração chamado **JenkinsFile**. Este arquivo possui um conjunto de "stages" para executar cada passo da construção da imagem/código.

### Git

Para atender aos requisitos do **GitOps** o **Jenkinsx** usa o git para armazenar dois tipos de dados:

#### Repositório da aplicação/sistema.

Neste repositório deve conter o código do aplicativo específico, repositório de trabalho de desenvolvedores. Cada aplicativo deve estar associado à um repositório Git, e, além do código também deve-se incluir:

- **Jenkinsfile**: Declaração da configuração do pipeline do jenkins para o aplicativo;
- **Dockerfile**: Instruções da construção da imagem Docker do aplicativo;
- **Diretório do Charts**: Conjunto de gráficos do aplicativo;
-- Configuração do chart para a versão do aplicativo. Usado quando a versão do aplicativo é criada (No primeiro momento é promovido para todo o ambiente). Também inclui o arquivo Makefile com descrição de como constuir o versionamento;
-- Configuração do charts preview. Usado somente quando o Git PR é configurado para criação de uma Branch de feature. Facilita um processo de revisão antes de aprovação de mesclagem da branch. Também inclui um arquivo Makefile com descrição da construção de visualização.

### Repositório do Ambiente

Repositório com arquivos de configuração que descrevem o ambiente da aplicação. Cada ambiente está associado a um repositório do Git e deve incluir:
- **JenkinsFile** - Possui a configuração de pipeline do Jenkins referente ao ambiente da aplicação. Em conjunto com o arquivo Makefile descreve as etapas de (re) construir o ambiente;
- **Makefile** - Comandos de criação do ambiente. Depende dos recursos do Helm (upgrade helm);
- **Diretório env** - Configuração do conteúdo do ambiente. Quais aplicativos de quais versões devem ser deployadas.

### Gitops

O que é o GitOps? É um conjunto de princípios para gerenciar software e infraestrutura baseados no Git:

- O Git é considera uma fonte de verdade para tudo, desde o código até a configuração dos ambientes.
- Quaisquer alterações operacionais, incluindo atualizaço de configuração de ambientes, são feitas por meio de solicitaço **pull**.
- Código de infraestrutura declarativa é implícita.

 Para cada uma das aplicações, o repositório Git correspondente é criado. Diferentes versões de aplicativos podem ser implantadas (promovidas) para diferentes ambientes em k8s, mas apenas através da alteração da configuração de um ambiente particular no Git.

### JenkinsX CLI

 O Jenkinsx CLI é utilizado para gerenciar recursos (aplicativos, ambientes, URLs, etc).
 Alguns dos comandos mais importantes:
 - **jx install** - Instala o JenkinsX no cluster k8s.
 - **jx create** - Cria recursos do JenkinsX e serviçoes associados (por exemplo: namespaces k8s, pods)
 - **jx import** - Importa um projeto (código) para o JenkinsX e, em seguida cria todos os objetos necessários dentro do repositório Git. (por exemplo: Helm Charts, JenkinsFile, etc)
 - **jx preview** - Cria um ambiente de preview temporário para visualização de uma versão de um aplicativo.
 - **jx promote** - Promove uma versão de aplicativo para um ambiente específico.

### JenkinsX Flow

  Abaixo um diagrama do ciclo de vida do desenvolvimento de um aplicativo desde o início até a implantação em ambiente de produção:

  <img src="https://i.imgur.com/BB5qNBA.png">

### JenkinxX - Criação Cluster

Abaixo está um diagrama mostrando o processo que o JX executa para a criação do cluster. 
- Pré-requisito: Para nstalação do JX é necessário ter o cluster Kubernetes.

<img src="https://i.imgur.com/iBvP5a3.png">

Depois que o JX é instalado, ele inicializa os Pods com os seguintes aplicativos no namespace jx do k8s:

- Chartmuseum (repositório de gráfico de Helm de código aberto)
- Registro do Docker (armazenamento de imagens do Docker)
- Jenkins (servidor de automação)
- MongoDB (banco de dados NoSQL)
- Repositório Nexus (armazenamento artefatos)

Além da instalação do Pod, o JX cria ambientes de "preparação" e "produção" que contêm versões de aplicativos em desenvolvimento. Essas configurações de ambientes são enviadas para repositórios remotos do Git e o webhook é criado para vincular à instalação do Jenkins no k8s.


Fonte: <a href="https://blog.octo.com/en/jenkinsx-new-kubernetes-dream-part-1/">Tradução Blog Octo</a>