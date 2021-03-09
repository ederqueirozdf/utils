DIA 03
Links:


https://www.doppler.com/​
Doppler

      - uses: dopplerhq/cli-action@v1  
      - name: set envs agent github actions
        run: doppler secrets download --no-file --format=docker >> $GITHUB_ENV; 
        env:
           DOPPLER_TOKEN: ${{ secrets.DOPPLER_TOKEN_PRD }}

FIREBASE

    import firebase from 'firebase';	
    ​
    const firebaseConfig = {	
        apiKey: "${VAR_API}",
        authDomain: "${VAR_AUTH}",
        projectId: "${VAR_PROJECT}",
        storageBucket: "${VAR_STORAGE}",
        messagingSenderId: "${VAR_MESS}",
        appId: "${VAR_APP}"
    };	
    ​
    const firebaseApp = firebase.initializeApp(firebaseConfig);	
    ​
    const db = firebaseApp.firestore();	
    const auth = firebase.auth();	
    const provider = new firebase.auth.GoogleAuthProvider();	
    const storage = firebase.storage();
    ​
    export { auth, provider, storage, firebase };	
    export default db;  

    Action file CacheCDN

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
          - name: DEPLOY S3
            run: cd build && AWS_ACCESS_KEY_ID=${ACCESS_KEY} AWS_SECRET_ACCESS_KEY=${SECRET_KEY} aws s3 sync . s3://treinazap --acl public-read --delete
          - name: CLEAR CACHE
            run: AWS_ACCESS_KEY_ID=${ACCESS_KEY} AWS_SECRET_ACCESS_KEY=${SECRET_KEY} aws cloudfront create-invalidation --distribution-id E91FKLAV95EGI --path '/*'
    ​

Action file SonarQube - FINAL

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
          - name: BAIXANDO SONAR
            run: wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.6.0.2311-linux.zip && unzip sonar-scanner-cli-4.6.0.2311-linux.zip
          - name: ANALYSYS CODE
            run: ./sonar-scanner-4.6.0.2311-linux/bin/sonar-scanner -Dsonar.projectKey=treinazap -Dsonar.sources=. -Dsonar.host.url=http://sonar.treinazap.cf/ -Dsonar.login=f8bd26c97c0a55fd7a4cfae46160766153ab01f8
          - name: DEPLOY S3
            run: cd build && AWS_ACCESS_KEY_ID=${ACCESS_KEY} AWS_SECRET_ACCESS_KEY=${SECRET_KEY} aws s3 sync . s3://treinazap --acl public-read --delete
          - name: CLEAR CACHE
            run: AWS_ACCESS_KEY_ID=${ACCESS_KEY} AWS_SECRET_ACCESS_KEY=${SECRET_KEY} aws cloudfront create-invalidation --distribution-id E91FKLAV95EGI --path '/*'
    ​

​
Adicionando SWAP

  sudo /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=2048
  sudo /sbin/mkswap /var/swap.1
  sudo chmod 600 /var/swap.1
  /sbin/swapon /var/swap.1
  sudo echo "/var/swap.1   none   swap  sw  0  0" | sudo tee -a /etc/fstab

Install Ambiente Docker

  sudo bash
  sudo amazon-linux-extras install docker
  sudo service docker start
  sudo systemctl enable docker
  sudo usermod -a -G docker ec2-user
  sudo docker run -p 80:80 -p 443:443 -p 3000:3000 -v /var/run/docker.sock:/var/run/docker.sock -v /captain:/captain caprover/caprover
  ​

CLEAR MEMORY

  sync; echo 1 > /proc/sys/vm/drop_caches
  sync; echo 2 > /proc/sys/vm/drop_caches
  sync; echo 3 > /proc/sys/vm/drop_caches

