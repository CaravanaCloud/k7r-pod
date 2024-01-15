#!/bin/bash
set -x

BASE_URL="https://openshift-release-artifacts.apps.ci.l2s4.p1.openshiftapps.com"
VERSION_TAG="4.15.0-rc.2" 

FILE_INSTALLER="openshift-install-linux-${VERSION_TAG}.tar.gz"
URL_INSTALLER="${BASE_URL}/${VERSION_TAG}/${FILE_INSTALLER}"
TEMP_INSTALLER="/tmp/openshift-install"

mkdir -p '${TEMP_INSTALLER}
wget -nv -O '${TEMP_INSTALLER}/${FILE_INSTALLER}' '${INSTALL_URL}'
tar zxvf '${TEMP_INSTALLER}/${FILE_INSTALLER}' -C '${TEMP_INSTALLER}' \
    && sudo mv  '${TEMP_INSTALLER}/openshift-install' '/usr/local/bin/' \    
    && rm '${TEMP_INSTALLER}/${FILE_INSTALLER}' \
    && openshift-install version \
