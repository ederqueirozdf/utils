# Uteis Openshift

### Gerar CA openshift para proxy reverso externo:

    export CA=/etc/origin/master

    oc adm ca create-server-cert --signer-cert=$CA/ca.crt --signer-key=$CA/ca.key --signer-serial=$CA/ca.serial.txt --hostnames='*.apps.dominio.com.br' --cert=cloudapps.crt --key=cloudapps.key

### Configuração de plugin para expansão de volumes

    # vim /etc/orgin/master/master-config.yaml

**Bloco de configuração para habilitação do plugin PersistentVolumeClaimResize**

    admissionConfig:                                                                                                        
      pluginConfig:                                                                                                         
        PersistentVolumeClaimResize:                                                                                        
          configuration:                                                                                                    
            apiVersion: v1                                                                                                  
            disable: true                                                                                                   
            kind: DefaultAdmissionConfig

**Após alteração do arquivo de configuração dos nodes masters, reiniciar os serviços:**

    # master-restart controllers
    # master-restart api

<hr>

# Configurar HPA Resource memória

    vi /etc/origin/master/master-config.yaml

**Habilitar recurso autoscaling nos parâmetros de apiServerArguments:**

      runtime-config:
      - apis/autoscaling/v2beta1=true

**Reinicializar serviços de api e controllers dos hosts masters:**

    # master-restart controllers
    # master-restart api

**Arquivo hpa.yaml **

        {{- if .Values.hpa.enabled }}
        apiVersion: autoscaling/v2beta1
        kind: HorizontalPodAutoscaler
        metadata:
          name: {{ template "fullname" . }}
          labels:
            chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
        spec:
          scaleTargetRef:
            apiVersion: v1
            kind: DeploymentConfig
            name: {{ template "fullname" . }}
          minReplicas: {{ .Values.hpa.minReplicas }}
          maxReplicas: {{ .Values.hpa.maxReplicas }}
          metrics:
          - type: Resource
            resource:
              name: cpu
              targetAverageUtilization: {{ .Values.hpa.cpuTargetAverageUtilization }}
          - type: Resource
            resource:
              name: memory
              targetAverageUtilization: {{ .Values.hpa.memoryTargetAverageUtilization }}
        {{- end }}

**Arquivo values com os parâmetros hpa.yaml **
    
        hpa:
          enabled: true
          minReplicas: 1
          maxReplicas: 2
          cpuTargetAverageUtilization: 90
          memoryTargetAverageUtilization: 80

# Falha Upgrade Kind / Release / Helm

    $ kubectl get cm -n kube-system -l OWNER=TILLER,STATUS=DEPLOYED 
    I ended up (brutally) deleting the extra CMs: 
    $ kubectl delete -n kube-system cm bar.v99.
