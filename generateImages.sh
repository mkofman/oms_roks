#!/bin/bash
# Licensed Materials - Property of IBM
# IBM Sterling Selling and Fulfillment Suite
# (C) Copyright IBM Corp. 2018 All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

T=`date +%Y_%m_%d_%H_%M_%S`

export RT=/opt/ssfs/runtime
mkdir -p $RT/logs
if [ -f "$RT/logs/generateImages.log" ]; then
    mv $RT/logs/generateImages.log $RT/logs/generateImages.log.$T
fi
exec 1> >(tee -a $RT/logs/generateImages.log)
exec 2>&1

function usage() {
    echo ""
    echo "Usage: <runtime/container-scripts/imagebuild>./generateImages.sh --MODE=<mode> <optional args>"
    echo ""
    echo "MODE - comma separated list of below supported values:"
    echo "	base    -Builds base runtime image"
    echo "	agent   -Builds light-weight agent runtime image"
    echo "	app     -Builds appserver image on top of websphere liberty"
    echo "	all     -Builds all 3 (base, agent, and app) images (Default)"
    echo "	docs    -Builds java docs image on top of websphere liberty"
    echo ""
    echo "Glossary of other args (overrides default values)-"
    echo "  --MQ_JARS_DIR=<Directory where mq jars reside, which can be imported into image> (Mandatory first time. Once jars are installed in runtime, this need not be passed any more.)"
    echo "  --SKIP_MQ_CHECK=<Skip pausing of script if MQ_JARS_DIR not found or passed> (Default- false)"
    echo "  --SKIP_BUILDEAR=<Skips building ear if ear already present> (Default- false)"
    echo "  --BUILD_JAVA_DOCS=<Builds java docs to xapidocs directory, docs mode only> (Default- true)"
    echo "  --BASE_DF=<Dockerfile for base runtime image> (Default- <RT>/container-scripts/imagebuild/Dockerfile.om-base)"
    echo "  --AGENT_DF=<Dockerfile for light-weight agent runtime image> (Default- <RT>/container-scripts/imagebuild/Dockerfile.om-agent)"
    echo "  --APP_DF=<Dockerfile for appserver image> (Default- <RT>/container-scripts/imagebuild/Dockerfile.om-app)"
    echo "  --DOCS_DF=<Dockerfile for javadoc server image> (Default- <RT>/container-scripts/imagebuild/Dockerfile.om-app-docs)"
    echo "  --BASE_REPO=<Repository name of base runtime image> (Default- om-base)"
    echo "  --AGENT_REPO=<Repository name of light-weight agent runtime image> (Default- om-agent)"
    echo "  --APP_REPO=<Repository name of appserver image> (Default- om-app)"
    echo "  --DOCS_REPO=<Repository name of javadoc server image> (Default- om-app-docs)"
    echo "  --OM_TAG=<Single tag for all images> (Default- latest)"
    echo "  --BASE_TAG=<Tag of base runtime image> (Default- \$OM_TAG)"
    echo "  --AGENT_TAG=<Tag of light-weight agent runtime image> (Default- \$OM_TAG)"
    echo "  --APP_TAG=<Tag of appserver image> (Default- \$OM_TAG)"
    echo "  --DOCS_TAG=<Tag of javadoc server image> (Default- \$OM_TAG)"
    echo "  --LIBERTY_IMG=<Liberty image <registry>/<name> for app images> (Default- ibmcom/websphere-liberty)" 
    echo "  --WAR_FILES=<Comma separated list of all war files to build ear. Colon can be used to group different war files to build segregated om-app images. Ex: smcfs,sbc:sma,isccs - This results in two appserver images om-app and om-app-isccs-sma with mentioned war files. The appserver images containing smcfs is always named om-app. For all other images, the war names are sorted alphabetically and hyphenated.> (Default- smcfs,sbc,sma + isccs,wsc,sfs if installed)"
    echo "  --DEV_MODE=<Pass -Ddevmode flag to build EAR> (Default- false)"
    echo "  --EXPORT=<Exports tarballs for generated images true|false> (Default- true)"
    echo "  --EXPORT_ONLY=<Exports tarballs and removes the generated images true|false> (Default- false)"
    echo "  --EXPORT_DIR=<Directory where generated image tarballs will be exported> (Default- <runtime>/../)"
    echo "  --DB_SCHEMA_OWNER=<DB schema> (Default- OMDB)"
    echo "  --DB_DATASOURCE=<DB datasource> (Default- jdbc/OMDS)"
    echo "  --DPM=<true|false>"
    echo "  --APP_DIFF_TAG=<Tag of reference app image for building differential om-app images. This is assumed to be same for all the reference images in grouped om-app images.>"
    echo "  --AGENT_DIFF_TAG=<Tag of reference agent image for building differential om-agent image>"
    echo "  --MQ_VER=<Version of MQ of downloaded jars> (Default- 9_2)"
    echo "  --ARCH=<(optional) architecture of the underlying OS. Supported values : 'amd64' and 'ppc64le'.If not specified, architecture will be auto detected>"
    echo "  --help - Show this help message"
    echo ""
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
    --MODE)
        export MODE=$VALUE
        ;;
    --EXPORT)
        export EXPORT=$VALUE
        ;;
    --EXPORT_ONLY)
        export EXPORT_ONLY=$VALUE
        ;;
    --EXPORT_DIR)
        export EXPORT_DIR=$VALUE
        ;;
    --ARCH)
        export ARCH=$VALUE
        ;;
    --MQ_JARS_DIR)
        export MQ_JARS_DIR=$VALUE
        ;;
    --SKIP_MQ_CHECK)
        export SKIP_MQ_CHECK=$VALUE
        ;;
    --SKIP_BUILDEAR)
        export SKIP_BUILDEAR=$VALUE
        ;;
    --BUILD_JAVA_DOCS)
        export BUILD_JAVA_DOCS=$VALUE
        ;;
    --BASE_REPO)
        export BASE_REPO=$VALUE
        ;;
    --BASE_TAG)
        export BASE_TAG=$VALUE
        ;;
    --BASE_DF)
        export BASE_DF=$VALUE
        ;;
    --AGENT_REPO)
        export AGENT_REPO=$VALUE
        ;;
    --AGENT_TAG)
        export AGENT_TAG=$VALUE
        ;;
    --AGENT_DF)
        export AGENT_DF=$VALUE
        ;;
    --APP_REPO)
        export APP_REPO=$VALUE
        ;;
    --APP_TAG)
        export APP_TAG=$VALUE
        ;;
    --APP_DF)
        export APP_DF=$VALUE
        ;;
    --DOCS_REPO)
        export DOCS_REPO=$VALUE
        ;;
    --DOCS_TAG)
        export DOCS_TAG=$VALUE
        ;;
    --DOCS_DF)
        export DOCS_DF=$VALUE
        ;;
    --OM_TAG)
        export OM_TAG=$VALUE
        ;;
    --WAR_FILES)
        export WAR_FILES=$VALUE
        ;;
    --DEV_MODE)
        export DEV_MODE=$VALUE
        ;;
    --DB_SCHEMA_OWNER)
        export DB_SCHEMA_OWNER=$VALUE
        ;;
    --DB_DATASOURCE)
        export DB_DATASOURCE=$VALUE
        ;;
    --DPM)
        export DPM=$VALUE
        ;;
    --APP_DIFF_TAG)
        export APP_DIFF_TAG=$VALUE
        ;;
    --AGENT_DIFF_TAG)
        export AGENT_DIFF_TAG=$VALUE
        ;;
    --MQ_VER)
        export MQ_VER=$VALUE
        ;;
    --LIBERTY_IMG)
        export LIBERTY_IMG=$VALUE
        ;;
    --help)
        usage
        exit 0
        ;;
    *)
        echo "ERROR: unknown parameter \"$PARAM\""
        usage
        exit 1
        ;;
    esac
    shift
done

export AUTO_ARCH=$(a=$(arch); [ $a == "x86_64" ] && echo "amd64" || echo $a)
export ARCH=${ARCH:-"$AUTO_ARCH"}
export BUILDAH_FORMAT=${BUILDAH_FORMAT:-"docker"}
export BUILDAH_RUNTIME=${BUILDAH_RUNTIME:-"runc"}

export MODE=${MODE:-"all"}
export EXPORT=${EXPORT:-"true"}
export EXPORT_ONLY=${EXPORT_ONLY:-"false"}
export EXPORT_DIR=${EXPORT_DIR:-"$RT/.."}

export SKIP_MQ_CHECK=${SKIP_MQ_CHECK:-"false"}
export SKIP_BUILDEAR=${SKIP_BUILDEAR:-"false"}
export BUILD_JAVA_DOCS=${BUILD_JAVA_DOCS:-"true"} # build the javadocs from RT/bin ./sci_ant.sh command (docs mode only). Can set this to false if docs are already built

export BASE_LABEL=om-base
export AGENT_LABEL=om-agent
export APP_LABEL=om-app
export TAG_LABEL=10.0
export DOCS_LABEL=om-app-docs

export BASE_DF=${BASE_DF:-"$RT/container-scripts/imagebuild/Dockerfile.$BASE_LABEL"}
export AGENT_DF=${AGENT_DF:-"$RT/container-scripts/imagebuild/Dockerfile.$AGENT_LABEL"}
export APP_DF=${APP_DF:-"$RT/container-scripts/imagebuild/Dockerfile.$APP_LABEL"}
export DOCS_DF=${DOCS_DF:-"$RT/container-scripts/imagebuild/Dockerfile.$DOCS_LABEL"}

export DIFF_DF="$RT/container-scripts/imagebuild/Dockerfile.diff-build"
export APP_LIB_DF="$RT/container-scripts/imagebuild/Dockerfile.om-app-libs"

export BASE_REPO=${BASE_REPO:-"localhost/$BASE_LABEL"}
export AGENT_REPO=${AGENT_REPO:-"localhost/$AGENT_LABEL"}
export APP_REPO=${APP_REPO:-"localhost/$APP_LABEL"}
export APP_LIB_REPO=${APP_REPO}-libs
export DOCS_REPO=${DOCS_REPO:-"localhost/$DOCS_LABEL"}

export OM_TAG=${OM_TAG:-"$TAG_LABEL"}
export BASE_TAG=${BASE_TAG:-"$OM_TAG"}
export AGENT_TAG=${AGENT_TAG:-"$OM_TAG"}
export APP_TAG=${APP_TAG:-"$OM_TAG"}
export DOCS_TAG=${DOCS_TAG:-"$OM_TAG"}

export DB_DATASOURCE=${DB_DATASOURCE:-"jdbc/OMDS"}
export DB_SCHEMA_OWNER=${DB_SCHEMA_OWNER:-"OMDB"}

export MQ_VER=${MQ_VER:-"9_2_0_0"}
export LIBERTY_TAG=${LIBERTY_TAG:-"21.0.0.3-kernel-java8-ibmjava-ubi"}
export LIBERTY_DEFAULT_ADDONS="admincenter-1.0 jdbc-4.1 jndi-1.0 jsp-2.3 servlet-3.1 ssl-1.0 monitor-1.0 localConnector-1.0"
export LIBERTY_ADDONS=${LIBERTY_ADDONS:-"${LIBERTY_DEFAULT_ADDONS}"}

export LIBERTY_IMG=${LIBERTY_IMG:-"ibmcom/websphere-liberty"}

export ED=$RT/external_deployments_imagebuild
export ANT_OPTS="-Ddir.external=$ED"
export DOCKER_CTX=build_context
export CTX_DIR=$ED/$DOCKER_CTX

export OMS_VERSION=$(awk -F= '/ysc.version/ {print $2}' $RT/properties/versioninfo.properties_ysc_ext)

echo "Generating images for mode '$MODE' ..."

build_app() {
    date
    echo "Preparing app image ..."

    echo "Installing mq jars if not present ..."
    install_mq_jars

    echo "Updating DB args if passed ..."
    update_db

    echo "Creating smcfs.ear ..."
date
mkdir -p $CTX_DIR
rm -rf $CTX_DIR/*
    export WARS="smcfs,sbc,sma"
    for WAR in ""isccs wsc""; do
        if [ -f "$RT/bin/build.properties_${WAR}_ext" ]; then
            WARS="$WARS,$WAR"
        fi
    done
    export WAR_FILES=${WAR_FILES:-"$WARS"}
    if [[ $(echo ${WAR_FILES//:/ } | wc -w) -gt 1 ]] && [ $SKIP_BUILDEAR == "true" ]; then
        echo -e "WAR_FILES has different groups of applications ($WAR_FILES) but SKIP_BUILDEAR is passed as true.\nIgnoring SKIP_BUILDEAR as EAR has to be built for each group."
        SKIP_BUILDEAR="false"
    fi
    if [ $SKIP_BUILDEAR = "true" ] && [ -f ${ED}/smcfs.ear ]; then
        echo "SKIP_BUILDEAR set to true & ${ED}/smcfs.ear found. Skipping ear building ..."
    else
        echo "Building EAR for WAR_FILES ${WAR_FILES//:/,} in DEV_MODE=${DEV_MODE:-"false"} ..."
        cd $RT/bin
        ./buildear.sh -Dappserver=websphere -Dwarfiles=${WAR_FILES//:/,} -Dearfile=smcfs.ear $([ ${DEV_MODE} == "true" ] && echo "-Ddevmode=true") -Dnowebservice=true -Dnoejb=true -Dnodocear=true
    fi
    if [ ! -f ${ED}/smcfs.ear ]; then
        echo "smcfs.ear not found. Exiting ..."
        exit 1
    fi
    mkdir -p $CTX_DIR
    rm -rf $CTX_DIR/*
    EAR_DIR_WRAPPER=smcfs.ear.dir
    EAR_COPY_DIR=smcfs.ear.copy
    cd $CTX_DIR
    cp ../smcfs.ear smcfs.ear1
    mkdir -p smcfs.ear
    cd smcfs.ear
    jar -xf ../smcfs.ear1
    for f in $(find . -type f -name "*.war" -o -name "properties.jar" -o -name "resources.jar"); do
        war=$(realpath $f)
        echo "exploding ${war}"
        mv ${war} ${war}1
        mkdir -p ${war}
        pushd ${war} 1>/dev/null && jar -xf ${war}1 && popd 1>/dev/null
        rm -f ${war}1
    done
    rm -vf properties.jar/safestart.properties
    cd ../
    rm -rf smcfs.ear1
    #tar -cf smcfs.ear.tar smcfs.ear
    mkdir -p $EAR_DIR_WRAPPER && rm -rf $EAR_DIR_WRAPPER/* && mv smcfs.ear $EAR_DIR_WRAPPER/.
    cp -r $RT/container-scripts/utils $EAR_DIR_WRAPPER/

    echo "Copying db driver jar to ear directory"
    export JDBC_DRIVER=$(cat $RT/properties/sandbox.cfg | grep "^JDBC_DRIVER=" | head -n1 | cut -d'=' -f2)
    if [ ! -f $JDBC_DRIVER ]; then
        echo "$JDBC_DRIVER not found. Exiting ..."
        exit 1
    fi
    cp -a $JDBC_DRIVER $CTX_DIR/
    export DDJ=`basename $JDBC_DRIVER`

    [ -d /licenses ] && (cp -r /licenses $CTX_DIR/LICENSES) || (mkdir $CTX_DIR/LICENSES && touch $CTX_DIR/LICENSES/LICENSE.txt)

    if [ -z $APP_DIFF_TAG ]; then
        echo "Building common image for ${APP_LABEL} libraries ..."
        buildah bud -t ${APP_LIB_REPO}:${TAG_LABEL} --format=${BUILDAH_FORMAT} --runtime=${BUILDAH_RUNTIME} -v $(realpath $EAR_DIR_WRAPPER):/home/default/context:z \
            -v /var/opt/ssfs/liberty-addons:/features:z --force-rm --pull --no-cache --build-arg DB_DRIVER_JAR=$DDJ --build-arg IMG_VERSION=${OMS_VERSION} \
            --build-arg UPDATE_PKGS=${APP_PKG_UPDATES} --build-arg LIBERTY_TAG=${LIBERTY_TAG} --build-arg LIBERTY_IMG=${LIBERTY_IMG} --build-arg LIBERTY_ADDONS="${LIBERTY_ADDONS}" -f $APP_LIB_DF $CTX_DIR
    fi

    for war_files in ${WAR_FILES//:/ }; do
        war_files=$(echo -e ${war_files//,/\\n} | sort | sed -e ':x {N;s/\n/,/;bx}')

        date
        export APP_IMG_LABEL=${APP_LABEL}$([[ ! $war_files =~ smcfs ]] && echo "-${war_files//,/_}")
        export APP_REPO_LABEL=${APP_REPO}$([[ ! $war_files =~ smcfs ]] && echo "-${war_files//,/_}")
        if [ -z $APP_DIFF_TAG ]; then
            echo "Build image from dockerfile"
            if [ ! -f $APP_DF ]; then
                echo "$APP_DF not found. Exiting ..."
                exit 1
            fi
            cp -a $APP_DF $CTX_DIR/
            export APP_DF_PATH=$CTX_DIR/$(basename $APP_DF)
            echo "Copying Dockerfile to context and using APP_DF==$APP_DF_PATH"
            buildah bud -t ${APP_IMG_LABEL}:${TAG_LABEL} --format=${BUILDAH_FORMAT} --runtime=${BUILDAH_RUNTIME} -v $(realpath $EAR_DIR_WRAPPER):/home/default/context:z --force-rm --pull --no-cache --build-arg APP_LIB_IMG="${APP_LIB_REPO}:${TAG_LABEL}" --build-arg WAR_FILES=${war_files} -f $APP_DF_PATH $CTX_DIR
        else
            echo "Build differential image from dockerfile"
            if [ ! -f $DIFF_DF ]; then
                echo "$DIFF_DF not found. Exiting ..."
                exit 1
            fi
            buildah pull -q --tls-verify=false $APP_REPO_LABEL:$APP_DIFF_TAG 2>/dev/null 1>/dev/null
            if [[ ! $? -eq 0 ]]; then
                echo "ERROR: $APP_REPO_LABEL:$APP_DIFF_TAG does not exist! Exiting ..."
                exit 1
            fi
            cp -a $DIFF_DF $CTX_DIR/
            export APP_DF_PATH=$CTX_DIR/$(basename $DIFF_DF)
            echo "Copying Dockerfile to context and using DIFF_DF==$APP_DF_PATH"
            mkdir -p $EAR_COPY_DIR && rm -rf $EAR_COPY_DIR/* && cp -R $EAR_DIR_WRAPPER/* $EAR_COPY_DIR/
            find $EAR_COPY_DIR -mindepth 2 -maxdepth 2 -name "*.war" $(for war in ${war_files/,/ }; do echo "-not -name ${war}.war"; done) -exec rm -rf {} +
            buildah bud -t ${APP_IMG_LABEL}:${TAG_LABEL} --format=${BUILDAH_FORMAT} --runtime=${BUILDAH_RUNTIME} -v $(realpath $EAR_COPY_DIR):/home/default/context:z --force-rm --pull --no-cache --build-arg REFERENCE_IMG=$APP_REPO_LABEL:$APP_DIFF_TAG --build-arg TARGET_DIR="/config/dropins/smcfs.ear" --build-arg CURRENT_DIR="/home/default/context/smcfs.ear" -f $APP_DF_PATH $CTX_DIR
        fi
        buildah tag ${APP_IMG_LABEL}:${TAG_LABEL} ${APP_REPO_LABEL}:${APP_TAG}
        rm -rf $APP_DF_PATH $EAR_COPY_DIR
        if [ $(buildah images --filter "label=intermediate" -q | wc -l) -gt 0 ]; then
            buildah rmi $(buildah images --filter "label=intermediate" -q)
        fi

        if [[ ${EXPORT} = "true" || ${EXPORT_ONLY} = "true" ]]; then
            echo "Saving app image tar ..."
            date
            rm -rf ${EXPORT_DIR}/${APP_IMG_LABEL}_${TAG_LABEL}.tar.gz
            buildah push ${APP_IMG_LABEL}:${TAG_LABEL} docker-archive:${EXPORT_DIR}/${APP_IMG_LABEL}_${TAG_LABEL}.tar:localhost/${APP_IMG_LABEL}:${TAG_LABEL}
            if [[ $? -eq 0 && ${EXPORT_ONLY} = "true" ]]; then
                buildah rmi ${APP_IMG_LABEL}:${TAG_LABEL}
                echo "Removed app docker image ..."
            fi
            gzip <${EXPORT_DIR}/${APP_IMG_LABEL}_${TAG_LABEL}.tar >${EXPORT_DIR}/${APP_IMG_LABEL}_${TAG_LABEL}.tar.gz && rm -f ${EXPORT_DIR}/${APP_IMG_LABEL}_${TAG_LABEL}.tar
        fi
    done
    rm -rf $CTX_DIR/$DDJ $CTX_DIR/LICENSES $EAR_DIR_WRAPPER
    date
}

build_base() {
    date
    echo "Preparing base image ..."

    if [ $MODE != "all" ]; then
        echo "Installing mq jars if not present ..."
        install_mq_jars

        echo "Updating DB args if passed ..."
        update_db
    fi

    echo "Preparing base tar ..."
    date
    mkdir -p $CTX_DIR
    rm -rf $CTX_DIR/*
    FILE=${BASE_LABEL}.tar.gz
    rm -rf $ED/$FILE
    cd $RT
cat <<EOF | tar --exclude-from=- -cf $ED/$FILE .
tmp/*
external_deployments
external_deployments_imagebuild
installed_data
middleware
logs/*
xapidocs/*
repository/entitybuild
platformrcp
jdk/Logs
$(find -name "*.log" -exec echo "{}" \;)
$(find -type d -name backups -exec echo "{}/*" \;)
EOF
    if [ ! -f $ED/$FILE ]; then
        echo "$ED/$FILE not found. Exiting ..."
        exit 1
    fi

    echo "Build image from dockerfile"
    date
    if [ ! -f $BASE_DF ]; then
        echo "$BASE_DF not found. Exiting ..."
        exit 1
    fi
    cp -a $BASE_DF $CTX_DIR/
    mv $ED/$FILE $CTX_DIR/.
    [ -d /licenses ] && (cp -r /licenses $CTX_DIR/LICENSES) || (mkdir $CTX_DIR/LICENSES && touch $CTX_DIR/LICENSES/LICENSE.txt)
    if [ -f /opt/ssfs/entrypoint.sh ]; then
        cp /opt/ssfs/entrypoint.sh $CTX_DIR/
    else
        cp $RT/container-scripts/imagebuild/entrypoint.sh $CTX_DIR/
    fi
    cp -a /var/opt/ssfs/rpms $CTX_DIR/
    cp -a ${RT}/database/db2/dbbackupdir/OMDB.tar.gz $CTX_DIR/
    export BASE_DF=$CTX_DIR/$(basename $BASE_DF)
    echo "Copying Dockerfile to context and using BASE_DF==$BASE_DF"
    buildah bud -t ${BASE_LABEL}:${TAG_LABEL} --format=${BUILDAH_FORMAT} --runtime=${BUILDAH_RUNTIME} -v /var/opt/ssfs/liberty-addons:/liberty-addons:z \
    -v $CTX_DIR:/tmp:z --force-rm --pull-always --no-cache --cap-add "cap_ipc_lock,cap_ipc_owner,cap_sys_admin" --build-arg FILE=$FILE \
    --build-arg IMG_VERSION=${OMS_VERSION} --build-arg UPDATE_PKGS=${BASE_PKG_UPDATES} -f $BASE_DF $CTX_DIR
    buildah tag ${BASE_LABEL}:${TAG_LABEL} ${BASE_REPO}:${BASE_TAG}
    rm -rf $CTX_DIR/$FILE $BASE_DF
    if [ $(buildah images --filter "label=intermediate" -q | wc -l) -gt 0 ]; then
        buildah rmi $(buildah images --filter "label=intermediate" -q)
    fi

    if [[ ${EXPORT} = "true" || ${EXPORT_ONLY} = "true" ]]; then
        echo "Saving base image tar ..."
        date
        rm -rf ${EXPORT_DIR}/${BASE_LABEL}_${TAG_LABEL}.tar.gz
        buildah push ${BASE_LABEL}:${TAG_LABEL} docker-archive:${EXPORT_DIR}/${BASE_LABEL}_${TAG_LABEL}.tar:localhost/${BASE_LABEL}:${TAG_LABEL}
        if [[ $? -eq 0 && ${EXPORT_ONLY} = "true" ]]; then
            buildah rmi ${BASE_LABEL}:${TAG_LABEL}
            echo "Removed base docker image ..."
        fi
        gzip <${EXPORT_DIR}/${BASE_LABEL}_${TAG_LABEL}.tar >${EXPORT_DIR}/${BASE_LABEL}_${TAG_LABEL}.tar.gz && rm -f ${EXPORT_DIR}/${BASE_LABEL}_${TAG_LABEL}.tar
    fi

    date
}

build_agent() {
    date
    echo "Preparing agent light-weight image ..."

    if [ $MODE != "all" ]; then
        echo "Installing mq jars if not present ..."
        install_mq_jars

        echo "Updating DB args if passed ..."
        update_db
    fi

    echo "Prepare agent tar ..."
    date
    mkdir -p $CTX_DIR
    rm -rf $CTX_DIR/*
    AGENT_FILE=${AGENT_LABEL}.tar.gz
    rm -rf $ED/$AGENT_FILE
    cd $RT/bin
    ./sci_ant.sh -f ../properties/buildRuntimeUtils.xml agentruntime -Dtar=$ED/$AGENT_FILE
    if [ ! -f $ED/$AGENT_FILE ]; then
        echo "$ED/$AGENT_FILE not found. Exiting ..."
        exit 1
    fi
    date
    mv $ED/$AGENT_FILE $CTX_DIR/.
    if [ -z $AGENT_DIFF_TAG ]; then
        echo "Build image from dockerfile"
        if [ ! -f $AGENT_DF ]; then
            echo "$AGENT_DF not found. Exiting ..."
            exit 1
        fi
        cp -a $AGENT_DF $CTX_DIR/
        [ -d /licenses ] && (cp -r /licenses $CTX_DIR/LICENSES) || (mkdir $CTX_DIR/LICENSES && touch $CTX_DIR/LICENSES/LICENSE.txt)
        export AGENT_DF_PATH=$CTX_DIR/$(basename $AGENT_DF)
        echo "Copying Dockerfile to context and using AGENT_DF==$AGENT_DF"
        echo "using architecture: $ARCH"
        buildah bud -t ${AGENT_LABEL}:${TAG_LABEL} --format=${BUILDAH_FORMAT} --runtime=${BUILDAH_RUNTIME} -v $CTX_DIR:/tmp:z --force-rm --pull-always --no-cache \
            --build-arg FILE=$AGENT_FILE --build-arg ARCH=${ARCH} --build-arg IMG_VERSION=${OMS_VERSION} --build-arg UPDATE_PKGS=${AGENT_PKG_UPDATES} -f $AGENT_DF_PATH $CTX_DIR
    else
        echo "Build differential image from dockerfile"
        if [ ! -f $DIFF_DF ]; then
            echo "$DIFF_DF not found. Exiting ..."
            exit 1
        fi
        buildah pull -q --tls-verify=false $AGENT_REPO:$AGENT_DIFF_TAG 2>/dev/null 1>/dev/null
        if [[ ! $? -eq 0 ]]; then
            echo "ERROR: $AGENT_REPO:$AGENT_DIFF_TAG does not exist! Exiting ..."
            exit 1
        fi
        cp -a $DIFF_DF $CTX_DIR/
        export AGENT_DF_PATH=$CTX_DIR/$(basename $DIFF_DF)
        mkdir -p $CTX_DIR/current
        tar -xf $CTX_DIR/$AGENT_FILE -C $CTX_DIR/current/
        echo "Copying Dockerfile to context and using DIFF_DF==$AGENT_DF_PATH"
        buildah bud -t ${AGENT_LABEL}:${TAG_LABEL} --format=${BUILDAH_FORMAT} --runtime=${BUILDAH_RUNTIME} -v $CTX_DIR:/tmp:z --force-rm --pull --no-cache --build-arg REFERENCE_IMG=$AGENT_REPO:$AGENT_DIFF_TAG --build-arg TARGET_DIR="$RT" --build-arg CURRENT_DIR="/tmp/current" -f $AGENT_DF_PATH $CTX_DIR
    fi

    buildah tag ${AGENT_LABEL}:${TAG_LABEL} ${AGENT_REPO}:${AGENT_TAG}
    rm -rf $CTX_DIR/$AGENT_FILE $CTX_DIR/current $AGENT_DF_PATH
    if [ $(buildah images --filter "label=intermediate" -q | wc -l) -gt 0 ]; then
        buildah rmi $(buildah images --filter "label=intermediate" -q)
    fi

    if [[ ${EXPORT} = "true" || ${EXPORT_ONLY} = "true" ]]; then
        echo "Saving agent image tar ..."
        date
        rm -rf ${EXPORT_DIR}/${AGENT_LABEL}_${TAG_LABEL}.tar.gz
        buildah push ${AGENT_LABEL}:${TAG_LABEL} docker-archive:${EXPORT_DIR}/${AGENT_LABEL}_${TAG_LABEL}.tar:localhost/${AGENT_LABEL}:${TAG_LABEL}
        if [[ $? -eq 0 && ${EXPORT_ONLY} = "true" ]]; then
            buildah rmi ${AGENT_LABEL}:${TAG_LABEL}
            echo "Removed agent docker image ..."
        fi
        gzip <${EXPORT_DIR}/${AGENT_LABEL}_${TAG_LABEL}.tar >${EXPORT_DIR}/${AGENT_LABEL}_${TAG_LABEL}.tar.gz && rm -f ${EXPORT_DIR}/${AGENT_LABEL}_${TAG_LABEL}.tar
    fi

    date
}

build_docs() {
    date
    echo "Preparing javadocs server image ..."

# if the parameter is not set to false, generate the javadocs with the ./sci_ant.sh script in RT/bin
    if [[ ${BUILD_JAVA_DOCS} = "true" ]]; then
        echo "Building java docs ..."
        cd $RT/bin
        ./sci_ant.sh -f ../properties/xapiDeployer.xml alldocs
    fi

    cd $RT
    echo "Creating smcfsdocs.ear ..."
    date
    mkdir -p $CTX_DIR
    rm -rf $CTX_DIR/*

# build smcfsdocs.ear in external_deployments unless they already exist and SKIP_BUILDEAR=true
    if [ $SKIP_BUILDEAR = "true" ] && [ -f ${ED}/smcfsdocs.ear ]; then
        echo "SKIP_BUILDEAR set to true & ${ED}/smcfsdocs.ear found. Skipping ear building ..."
    else
        echo "Building EAR for smcfsdoc..."
        cd $RT/bin
# modified: -Dnodocear=fale (in other modes, -Dnodocear=true)
        ./buildear.sh -Dappserver=websphere -Dwarfiles=smcfs -Dearfile=smcfs.ear -Dnowebservice=true -Dnoejb=true -Dnodocear=false
    fi

# if build of smcfsdocs.ear failed, exit build with error
    if [[ ! -f ${ED}/smcfsdocs.ear ]]; then
        echo "smcfsdocs.ear not found. Exiting ..."
        exit 1
    fi

# make and empty directory build_context
    mkdir -p $CTX_DIR
    rm -rf $CTX_DIR/*

# unzip smcfsdocs.ear inside external_deployments, move the smcfsdocs.ear directory into smcfsdocs.ear.dir
    EAR_DIR_WRAPPER=smcfsdocs.ear.dir
    cd $CTX_DIR
    cp ../smcfsdocs.ear smcfsdocs.ear1
    mkdir -p smcfsdocs.ear
    cd smcfsdocs.ear
    unzip ../smcfsdocs.ear1
    cd ..
    rm -rf smcfsdocs.ear1
    mkdir -p $EAR_DIR_WRAPPER && rm -rf $EAR_DIR_WRAPPER/* && mv smcfsdocs.ear $EAR_DIR_WRAPPER/.
    cp -r $RT/container-scripts/utils $EAR_DIR_WRAPPER/
    [ -d /licenses ] && (cp -r /licenses $CTX_DIR/LICENSES) || (mkdir $CTX_DIR/LICENSES && touch $CTX_DIR/LICENSES/LICENSE.txt)
# copy the docs dockerfile to build_context
    cp -a $DOCS_DF $CTX_DIR/.
    export DOCS_DF_PATH=$CTX_DIR/$(basename $DOCS_DF)
    echo "Copying Dockerfile to context and using DOCS_DF==$DOCS_DF_PATH"

# build the image using smcfsdocs.ear.dir as volume, docs dockerfile, in build_context context
    buildah bud -t ${DOCS_LABEL}:${TAG_LABEL} --format=${BUILDAH_FORMAT} --runtime=${BUILDAH_RUNTIME}  -v $(realpath $EAR_DIR_WRAPPER):/home/default/context:z \
        -v /var/opt/ssfs/liberty-addons:/features:z --force-rm --pull --no-cache --build-arg IMG_VERSION=${OMS_VERSION} \
        --build-arg UPDATE_PKGS=${APP_PKG_UPDATES} --build-arg LIBERTY_TAG=${LIBERTY_TAG} --build-arg LIBERTY_IMG=${LIBERTY_IMG} --build-arg LIBERTY_ADDONS="${LIBERTY_ADDONS}" -f $DOCS_DF_PATH $CTX_DIR

# tag the image
    buildah tag ${DOCS_LABEL}:${TAG_LABEL} ${DOCS_REPO}:${DOCS_TAG}

# remove docs dockerfile and smcfsdocs.ear.dir directory
    rm -rf $DOCS_DF_PATH $EAR_DIR_WRAPPER

# exporting the image
    if [[ ${EXPORT} = "true" || ${EXPORT_ONLY} = "true" ]]; then
        echo "Saving docs image tar ..."
        date
# remove existing image.tar.gz if it exists
        rm -rf ${EXPORT_DIR}/${DOCS_IMG_LABEL}_${TAG_LABEL}.tar.gz
# push to tar
        buildah push ${DOCS_LABEL}:${TAG_LABEL} docker-archive:${EXPORT_DIR}/${DOCS_LABEL}_${TAG_LABEL}.tar:localhost/${DOCS_LABEL}:${TAG_LABEL}
# remove the image if we're only exporting
        if [[ $? -eq 0 && ${EXPORT_ONLY} = "true" ]]; then
            buildah rmi ${DOCS_LABEL}:${TAG_LABEL}
            echo "Removed docs docker image ..."
        fi
# zip the .tar
        gzip <${EXPORT_DIR}/${DOCS_LABEL}_${TAG_LABEL}.tar >${EXPORT_DIR}/${DOCS_LABEL}_${TAG_LABEL}.tar.gz && rm -f ${EXPORT_DIR}/${DOCS_LABEL}_${TAG_LABEL}.tar
    fi
# remove directory
    rm -rf $EAR_DIR_WRAPPER
    date

}

install_mq_jars() {
    if [ ! -d "$RT/jar/mq/$MQ_VER" ]; then
        if [ -d "$MQ_JARS_DIR" ]; then
            #F=`ls $MQ_JARS_DIR -1U | wc -l`
            cd $MQ_JARS_DIR
            for JAR in *.jar; do
                $RT/bin/install3rdParty.sh mq $MQ_VER -j $MQ_JARS_DIR/$JAR -targetJVM EVERY
            done
        else
            echo ""
            echo "WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! "
            echo ""
            echo "Argument --MQ_JARS_DIR not passed or MQ_JARS_DIR="$MQ_JARS_DIR" not found. Please pass the correct directory, where you have all the applicable mq client jars, as an argument --MQ_JARS_DIR=<dir full path>. If you don't pass this, you won't be able to use MQ while deploying the generated images using Docker Compose or Kubernetes scripts."
            echo ""
            echo "WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! "
            echo ""

            if [ "$SKIP_MQ_CHECK" != "true" ]; then
                echo "SKIP_MQ_CHECK==$SKIP_MQ_CHECK="
                echo -e "Press Enter to continue without passing --MQ_JARS_DIR or Ctrl+C to exit. If you need not pass --MQ_JARS_DIR and don't want script to pause here, pass the argument --SKIP_MQ_CHECK=true."
                read -p ""
            fi
        fi
    fi
}

update_db() {
    ARGS="--DB_DATASOURCE=$DB_DATASOURCE --DB_SCHEMA_OWNER=$DB_SCHEMA_OWNER"
    if [ ! -z $DPM ]; then
        ARGS="${ARGS} --DATABASE_PROPERTY_MANAGEMENT=$DPM"
    fi
    cd $RT/bin
    ./prepareDB.sh $ARGS
}

for mode in ${MODE//,/ }; do
    case $mode in
    app)
        build_app
        ;;
    base)
        build_base
        ;;
    agent)
        build_agent
        ;;
    all)
        build_app
        build_base
        build_agent
        ;;
    docs)
        build_docs
        ;;
    *)
        echo "ERROR: '$mode' is not a supported MODE"
        usage
        ;;
    esac
done
