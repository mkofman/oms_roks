#!/usr/bin/bash

## Copyright (C) 2022 Arif Ali
## This program is free software: you can redistribute it and/or modify it under the terms 
## of the GNU General Public License as published by the Free Software Foundation, 
## either version 3 of the License, or (at your option) any later version. 
## This program is distributed in the hope that it will be useful, 
## but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
## or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
## for more details. You should have received a copy of the GNU General Public License 
## along with this program. If not, see https://www.gnu.org/licenses/.

## Exit out of an error
set -e

## To read env.sh file.
source $(dirname $(realpath ${0}))/env.sh
## Create Delete MQ file.
cat <<\EOF > delete_mq.sh
#!/usr/bin/bash

## Exit out of an error
set -e

## To read env.sh file.
source $(dirname $(realpath ${0}))/env.sh

oc project ${MQ_NAME}
envsubst < mq-roks.yaml | oc delete -f -
oc delete project ${MQ_NAME}
EOF
chmod +x delete_mq.sh
## Create new project, service account. Grant privileged SCC and create MQ instance.
oc new-project ${MQ_NAME}
oc create serviceaccount ${MQ_NAME}
oc adm policy add-scc-to-user privileged -n ${MQ_NAME} -z ${MQ_NAME}
## Check env.sh
if [ -z "$MQ_NAME" ] ; then
  echo "The name for the MQ installation must be defined in env.sh file."
  exit 1
fi
## Create deployment YAML
cat << EOF > mq-roks.yaml
apiVersion: v1
kind: Service
metadata:
  name: ${MQ_NAME}-data
spec:
  selector:
    app: ${MQ_NAME}
  type: ClusterIP
  ports:
  - protocol: TCP
    port: 1414
    targetPort: 1414
---
apiVersion: v1
kind: Service
metadata:
  name: ${MQ_NAME}-web
spec:
  selector:
    app: ${MQ_NAME}
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 9443
    targetPort: 9443
---
apiVersion: v1
kind: Route
metadata:
  name: ${MQ_NAME}-web
spec:
  tls:
    insecureEdgeTerminationPolicy: Redirect
    termination: passthrough
  to:
    kind: Service
    name: ${MQ_NAME}-web
  wildcardPolicy: None
---
apiVersion: v1 
kind: Secret 
metadata:
  name: ${MQ_NAME}-secret 
type: Opaque
data:
 adminPassword: cGFzc3cwcmQ= 
 appPassword: cGFzc3cwcmQ=
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ${MQ_NAME}
spec:
  selector:
    matchLabels:
      app: ${MQ_NAME}
  serviceName: "${MQ_NAME}"
  replicas: 1
  template:
    metadata:
      labels:
        app: ${MQ_NAME}
    spec:
      serviceAccount: ${MQ_NAME}
      containers:
      - name: ${MQ_NAME}
        securityContext:
          privileged: true
        image: ibmcom/mq
        env:
        - name: LICENSE 
          value: accept
        - name: MQ_QMGR_NAME
          value: qmgr
        ports:
        - containerPort: 1414
          name: mq
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: mqvol
          mountPath: /var/mqm
  volumeClaimTemplates:
  - metadata:
      name: mqvol
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 20Gi
      storageClassName: ibmc-block-gold
EOF
## Deploy
envsubst < mq-roks.yaml | oc create -f -

