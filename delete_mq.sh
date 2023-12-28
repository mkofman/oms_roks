#!/usr/bin/bash

## Exit out of an error
set -e

## To read env.sh file.
source $(dirname $(realpath ${0}))/env.sh

oc project ${MQ_NAME}
envsubst < mq-roks.yaml | oc delete -f -
oc delete project ${MQ_NAME}
