---
title: Set up DB2 on Windows
description: Set up DB2 Community Edition Container
slug: /deploy-db2-container
sidebar_position: 2
---

1. Create a suitable working directory on your local filesystem, eg. D:\ROKS

2. Login to your cluster and retrieve login credentials
- Launch [OpenShift cluster](https://cloud.ibm.com/kubernetes/clusters?platformType=openshift)
- Click on your cluster and the `OpenShift web console`
:::tip
You may want to create a new bookmark folder (eg ROKS) and place all the key bookmarks, such as the one above, in that folder.
Later on you can add direct links to the usual OMS tooling in there as well, among other things.
:::
- Click your login name top right and then select `Copy login command`
- Click on Display Token and copy the resulting **oc login** command. 
- Open a Windows command prompt and change directory to your newly created folder.
- Paste and execute your oc login command.
:::tip
If your session later expires at some point, just execute the login again to regain access to your cluster.
:::

3. Git clone the code.

```shell
git clone https://github.com/aroute/oms-guide.git
```
:::tip
You may copy & paste.
:::

4. Create an OpenShift project for DB2. In this example we are naming it "db2".


```shell
oc new-project db2
```

5. Create a Service Account and provide access policy.
```shell
oc create serviceaccount db2
```
```shell
oc adm policy add-scc-to-user privileged -n db2 -z db2
```

6. Deploy the container pod.
```shell
oc create -f db2-roks-windows.yaml
```

:::info
At this point in time, the deployment will automate the provisioning of the cloud storage device. It may take few minutes for the provisioning to complete. Wait a few minutes and then proceed forward.
:::

7. Check DB2 logs. ⏰
```shell
oc logs -f db2-0
```

8. Exit the log by hitting `Ctrl+c` when you see the following last output.
```text title="Expected Result"
// highlight-start
/database/config/db2inst1/sqllib/ctrl/db2strst.lck
// highlight-end
```

9. Copy DB2 SQL file to the container.
```shell
oc cp createDB.sql db2-0:/database/config/db2inst1/ 
```

10. Log in to the DB2 pod.
```shell
oc rsh pod/db2-0 su - db2inst1
```

11. From inside the pod, execute the script to create the `OMDB` instance. This will take a few minutes. ⏰
```shell
db2 -stvf createDB.sql
```

12. Validate the connection. This may take a few minutes. ⏰
```shell
db2 connect to OMDB user db2inst1 using xxxxxxxx
```
```text title="Expected Result"
// highlight-start
Database Connection Information

Database server        = DB2/LINUXX8664 11.5.5.0
SQL authorization ID   = DB2INST1
Local database alias   = OMDB
// highlight-end
```

13. Exit out of the DB2 pod.
```shell
exit
```

12. Retrieve DB2's LoadBalancer IP and Port, and record the values for later use.
```shell
oc get svc db2-lb -n db2 -o jsonpath='{.status.loadBalancer.ingress}'
```
```shell
oc get svc db2-lb -n db2 -o jsonpath='{.spec.ports[?(@.name=='db2-http')].nodePort}'
```

:::tip
You might additionally want to install some third party database query tool, such as DbVisualizer, for easy access to your database later on.
:::
---
title: Set up MQ
description: Set up IBM MQ.
slug: /mq-deploy
sidebar_position: 5
---
## Prepare MQ deployment

1. Create OpenShift project for MQ and set up security.
```shell
oc new-project mq
```
```shell
oc create serviceaccount mq
```
```shell
oc adm policy add-scc-to-user privileged -n mq -z mq
```

## Deploy MQ

2. Deploy MQ container.
```shell
oc create -f mq-roks.yaml
```

:::info
It will now take some time for the provisioning to complete. Wait a few minutes and then proceed forward.
:::


3. Copy the script.
```shell
oc cp queues.in mq-0:/mnt/mqm/data/
```
```shell
oc cp setmqauth.sh mq-0:/mnt/mqm/data/
```

4. Locate Load Balancer IP address.

- Go to your OpenShift cluster and launch the web console
- From the project dropdown, switch to `mq`
- Navigate down to **Networking > Services**
- Record the IP address and port next to the `mq-data-lb` entry (see the Location column)
 

## Set up Web UI

5. Navigate down to Networking > Routes. Next to mqweb, click on the Location URL. Log in using `admin/passw0rd`
6. Click down to Manage > Local queue managers (qmgr) > Communication > Listeners > SYSTEM.LISTENER.TCP.1 > the wrench icon . :wrench:
7. Click on Edit and update the IP address and Port with the values that you captured in previous step. Save the changes.
8. Navigate to qmgr > View Configuration (wrench) > Security > Authority records > Add (users)
- Add new user **mqm** and grant Connect and ability to modify the origin of messages (click all tickboxes) for this user.
> Admin level access is apparently not required though.

9. On the same page, select ... and refresh all three options (Refresh authorization, connection, SSL).

## Log in to the MQ container
```shell
oc rsh pod/mq-0
```
```shell
chmod +x setmqauth.sh
chmod +x queues.in
```
```shell
runmqsc qmgr < queues.in
```
```shell
./setmqauth.sh
```

## Configure JMS Queue
```shell
cp /opt/mqm/java/bin/JMSAdmin.config .
```
```shell
chmod +x JMSAdmin.config
```
```shell
mkdir JNDI 
```
Check that folder /mnt/mqm/data/JNDI was created.
```shell
sed -i 's=file:///home/user/JNDI-Directory=file:///mnt/mqm/data/JNDI=g' JMSAdmin.config
```

## Create JMS Queue

Before running the next block of command, update the host IP address X.X.X.X with your MQ Load Balancer IP.
```shell
cat <<EOF > inst.scp
define ctx(qmgr)
change ctx(qmgr)
def qcf(qcf) qmgr(qmgr) tran(CLIENT) chan(SYSTEM.ADMIN.SVRCONN) host(X.X.X.X) port(1414)
def q(DEFAULTAGENTQUEUE) qu(DEFAULTAGENTQUEUE) qmgr(qmgr)
end
EOF
```
```shell
/opt/mqm/java/bin/JMSAdmin -cfg /mnt/mqm/data/JMSAdmin.config < inst.scp
```
Check `ls -la JNDI/qmgr/`. There should be a `.bindings` file now.

Exit out of the container and download the `.bindings` file.
```shell
oc rsync mq-0:/mnt/mqm/data/JNDI/qmgr/.bindings .
```

There is one more configuration step left (`oc create configmap`). We will run that once the OMS pods have been deployed as well.

Create the ConfigMap object.
```shell
oc create configmap oms-binding --from-file=.bindings -n oms
```
---
title: Entitled Images
description: Pull/push entitled images.
slug: /entitled-images
sidebar_position: 3
---
## Entitled Registry

1. Log in to the [Container Software Library](https://myibm.ibm.com/products-services/containerlibrary) using your IBM ID. Click the Copy button to copy your key. Save it in a scratch pad file or a note somewhere near you.

2. Create a variable with the registry server location.
```shell
export ENTITLED_REG=cp.icr.io
on Windows: set ENTITLED_REG=cp.icr.io
```

3. Create a variable with your copied API key. Do not copy/paste this command as is.
```shell
export ENTITLED_REGISTRY_KEY=

on Windows: 
set ENTITLED_REGISTRY_KEY=
```

4. Create a variable for the image tag.

:::info
At this time of the writing (October 2021), the available entitled images are at the following level. This may change in the future.
:::

```console
export TAG=10.0.0.26-amd64

on Windows: 
set TAG=10.0.0.26-amd64
```

5. Create a variable for the registry location.
```shell
export LOC=ibm-oms-enterprise

on Windows: 
set LOC=ibm-oms-enterprise
```
(Alternatively you may refer to `ibm-oms-professional` for the Professional Edition)

6. Log in to the entitled registry.

:::caution
Ensure your docker client is already running on your computer. The following command will not work without a running docker client.
:::

```shell
docker login "$ENTITLED_REG" -u cp -p "$ENTITLED_REGISTRY_KEY"

on Windows: 
docker login "%ENTITLED_REG%" -u cp -p "%ENTITLED_REGISTRY_KEY%"
```

## Pull Entitled Images

7. Pull the images.
```shell
for n in ${ENTITLED_REG}/cp/${LOC}/om-base:${TAG} ${ENTITLED_REG}/cp/${LOC}/om-app:${TAG} ${ENTITLED_REG}/cp/${LOC}/om-agent:${TAG}; do docker pull ${n}; done

on Windows:
docker pull %ENTITLED_REG%/cp/%LOC%/om-base:%TAG%
docker pull %ENTITLED_REG%/cp/%LOC%/om-app:%TAG%
docker pull %ENTITLED_REG%/cp/%LOC%/om-agent:%TAG%
```

## Prepare OpenShift Registry

8. Prepare OpenShift Registry by running the following two commands.
```shell
oc create route reencrypt --service=image-registry -n openshift-image-registry
```
```shell
oc patch route image-registry -n openshift-image-registry -p '{ "metadata": { "annotations": {"haproxy.router.openshift.io/balance": "source" }}}'

on Windows:
Open a PowerShell command prompt. Then run this:
oc patch route image-registry -n openshift-image-registry -p '{\"metadata\": {\"annotations\": {\"haproxy.router.openshift.io/balance\": \"source\"}}}'

```

## Create OpenShift Project for OMS

9. Create a new project for OMS deployment.
```shell
oc new-project oms
```

10. Set up variables for images.
```shell
export REG=$(oc get route image-registry -n openshift-image-registry -o jsonpath='{.spec.host}')

on Windows:
oc get route image-registry -n openshift-image-registry -o jsonpath='{.spec.host}'

then copy paste the value accordingly:
set REG=<paste from above>
```
```shell
export PROJECT=$(oc config view --minify -o 'jsonpath={..namespace}')

on Windows:
set PROJECT=oms
```

## Log in to OpenShift Registry

11. Using your registry server's address saved in the variable above, log in through docker.
```shell
docker login -u $(oc whoami) -p $(oc whoami -t) $REG

on Windows:
First find out what your <userid> and <password> is:
oc whoami
oc whoami -t

then copy paste the values to the following command:
docker login -u <userid> -p <password> %REG%
```

## Tag and prepare Images 

12. Tag the earlier pulled entitled images with your registry information.
```shell
docker tag ${ENTITLED_REG}/cp/${LOC}/om-agent:${TAG} ${REG}/${PROJECT}/om-agent:${TAG}

docker tag ${ENTITLED_REG}/cp/${LOC}/om-app:${TAG} ${REG}/${PROJECT}/om-app:${TAG}
```
on Windows:
```shell
docker tag %ENTITLED_REG%/cp/%LOC%/om-agent:%TAG% %REG%/%PROJECT%/om-agent:%TAG%

docker tag %ENTITLED_REG%/cp/%LOC%/om-app:%TAG% %REG%/%PROJECT%/om-app:%TAG%
```
## Push entitled images to your OpenShift 

13. Push the downloaded entitled images to your OpenShift cluster.

```shell
docker push ${REG}/${PROJECT}/om-app:${TAG}

docker push ${REG}/${PROJECT}/om-agent:${TAG}
```

on Windows:
```shell
docker push %REG%/%PROJECT%/om-app:%TAG%

docker push %REG%/%PROJECT%/om-agent:%TAG%
```

