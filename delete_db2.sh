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

oc project ${DB2_NAME}
envsubst < db2-roks.yaml | oc delete -f -
oc delete project ${DB2_NAME}
