DIA 04
GITHUB ACTIONS

name: Deploy Treinazap - ECS
        ​
        on:
          workflow_dispatch:
        ​
        jobs:
          build:
            runs-on: ubuntu-18.04
            steps:
              - uses: actions/checkout@v2
              - uses: dopplerhq/cli-action@v1  
              - name: set envs agent github actions
                run: doppler secrets download --no-file --format=docker >> $GITHUB_ENV; 
                env:
                   DOPPLER_TOKEN: ${{ secrets.DOPPLER_TOKEN_PRD }}
        ​

              - uses: actions/setup-node@v1
                with:
                  node-version: 12.21.0
              - name: SET ENV FIREBASE
                run: envsubst <src/firebase-deploy.js> src/firebase.js
              - name: CHECK FILE
                run: cat src/firebase.js
              - name: INSTALL E BUILD
                run: npm install && npm run build
                env:
                   CI: "false"
              #- name: BAIXANDO SONAR
              #  run: wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.6.0.2311-linux.zip && unzip sonar-scanner-cli-4.6.0.2311-linux.zip
              #- name: ANALYSYS CODE
              # run: ./sonar-scanner-4.6.0.2311-linux/bin/sonar-scanner -Dsonar.projectKey=treinazap -Dsonar.sources=. -Dsonar.host.url=http://sonar.treinazap.cf/ -Dsonar.login=f8bd26c97c0a55fd7a4cfae46160766153ab01f8
        ​
        ​
              - name: Configure AWS credentials
                uses: aws-actions/configure-aws-credentials@v1
                with:
                  aws-access-key-id: ${{ env.ACCESS_KEY }}
                  aws-secret-access-key: ${{ env.SECRET_KEY }}
                  aws-region: us-east-1
        ​
              - name: Login to Amazon ECR
                id: login-ecr
                uses: aws-actions/amazon-ecr-login@v1
        ​
              - name: Build, tag, and push image to Amazon ECR
                id: build-image
                env:
                  ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
                  ECR_REPOSITORY: 160325706659.dkr.ecr.us-east-1.amazonaws.com/treinazap
                  IMAGE_TAG: ${{ github.sha }}
                run: |
                  docker build -t treinazap .
                  docker tag treinazap:latest $ECR_REPOSITORY:latest
                  docker push $ECR_REPOSITORY:latest
                  aws ecs update-service --cluster unicorniostech --service treinazap --force-new-deployment --region us-east-1
        ​
              - name: CLEAR CACHE
                run: AWS_ACCESS_KEY_ID=${ACCESS_KEY} AWS_SECRET_ACCESS_KEY=${SECRET_KEY} aws cloudfront create-invalidation --distribution-id E91FKLAV95EGI --path '/*'
        ​
