DIA 02

Comandos Play With Docker

apk update
apk add nodejs
apk add npm
git clone ​https://github.com/treinacloud/treinazap

GitHub Actions 

ATENÇÃO ALGUMAS VERSÕES DO GITHUB ACTIONS AGENT ESTÁ COM PROBLEMAS, USE MODELO A SEGUIR POIS ELE JÁ VEM COM O AWSCLI INSTALADO...

Alteramos a imagem de ubuntu-latest para ubuntu-18.04 e removemos o install AWSCLI

    name: Deploy Treinazap - S3
    ​
    on:
      workflow_dispatch:
    ​
    jobs:
      build:
        runs-on: ubuntu-18.04
        steps:
          - uses: actions/checkout@v2
          - uses: actions/setup-node@v1
            with:
              node-version: 12.21.0
          - name: INSTALL E BUILD
            run: npm install && npm run build
            env:
               CI: "false"
          - name: DEPLOY S3
            run: cd build && AWS_ACCESS_KEY_ID=${CHAVE} AWS_SECRET_ACCESS_KEY=${SENHA} aws s3 sync . s3://treinazap --acl public-read --delete
            env:
               CHAVE: ${{ secrets.ACCESS_KEY }}
               SENHA: ${{ secrets.SECRET_KEY }}
