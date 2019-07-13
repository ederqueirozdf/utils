# Exemplo prático de ConfigMap's e Secrets Kubernetes

## Criação da secret commandline Kubectl:

        kubectl create secret generic apikey --from-literal=API_KEY=123456

### Visualizar yaml

        kubectl create secret generic apikey --from-literal=API_KEY=123456 -o yaml --dry-run

## Criação do configMap commandline Kubectl:

        kubectl create configmap language --from-literal=LANGUAGE=English

## Configurando o containers no deployment

        containers:
         - name: envtest
           image: node.js
           ports:
           - containerPort: 3000
           env:
           - name: LANGUAGE
             valueFrom:
               configMapKeyRef:
               name: language
               key: LANGUAGE
           - name: API_KEY
             valueFrom:
               secretKeyRef:
                 name: apikey
                 key: API_KEY


## Substituição de Secrets e Configmaps

        kubectl create secret generic apikey --from-literal=API_KEY=123 -o yaml--dry-run | replace -f -

        kubectl create configmap language --from-literal=LANGUAGE=Spanish -o yaml --dry-run | replace -f -



