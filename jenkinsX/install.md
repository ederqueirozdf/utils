# Instalação JenkinsX

### Linux
	mkdir -p ~/.jx/bin

	curl -L https://github.com/jenkins-x/jx/releases/download/v2.0.329/jx-linux-amd64.tar.gz | tar xzv -C ~/.jx/bin

	sudo mv jx /user/local/bin

	export PATH=$PATH:~/.jx/bin
	echo 'export PATH=$PATH:~/.jx/bin' >> ~./bashrc

# Criar novo Cluster

### Minikube

	jx create cluster minikube

### Atualização ingress cluster jx

	jx upgrade ingress --cluster

