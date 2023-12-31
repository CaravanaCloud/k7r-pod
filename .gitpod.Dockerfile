# docker build --no-cache --progress=plain -f .gitpod.Dockerfile .
FROM gitpod/workspace-full

# System
RUN bash -c "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EFE0E0A2F2F60AA"
RUN bash -c "echo 'deb http://ppa.launchpad.net/tektoncd/cli/ubuntu jammy main'|sudo tee /etc/apt/sources.list.d/tektoncd-ubuntu-cli.list"
RUN bash -c "sudo install-packages direnv gettext mysql-client gnupg golang"
RUN bash -c "sudo apt-get update"
RUN bash -c "sudo pip install --upgrade pip"

# OKD
# Installer from https://github.com/okd-project/okd/releases/download/4.14.0-0.okd-2023-12-01-225814/openshift-install-linux-4.14.0-0.okd-2023-12-01-225814.tar.gz
ARG REPO_URL="https://github.com/okd-project/okd/releases/download"
ARG RELEASE_TAG="4.14.0-0.okd-2023-12-01-225814"
ARG RELEASE_PKG="openshift-install-linux-4.14.0-0.okd-2023-12-01-225814.tar.gz"
ARG INSTALL_URL="${REPO_URL}/${RELEASE_TAG}/${RELEASE_PKG}"
ARG TEMP_DIR="/tmp/openshift-install"
ARG TEMP_FILE="openshift-install-linux.tar.gz"
RUN bash -c "mkdir -p '${TEMP_DIR}' \
    && wget -nv -O '${TEMP_DIR}/${TEMP_FILE}' '${INSTALL_URL}' \
    && tar zxvf '${TEMP_DIR}/${TEMP_FILE}' -C '${TEMP_DIR}' \
    && sudo mv  '${TEMP_DIR}/openshift-install' '/usr/local/bin/' \    
    && rm '${TEMP_DIR}/${TEMP_FILE}' \
    && openshift-install version \
    " 

# oc / kubectl
ARG RELEASE_PKG="openshift-client-linux-4.14.0-0.okd-2023-12-01-225814.tar.gz"
ARG INSTALL_URL="${REPO_URL}/${RELEASE_TAG}/${RELEASE_PKG}"
ARG TEMP_DIR="/tmp/openshift-client"
ARG TEMP_FILE="openshift-client-linux.tar.gz"
RUN bash -c "mkdir -p '${TEMP_DIR}' \
    && wget -nv -O '${TEMP_DIR}/${TEMP_FILE}' '${INSTALL_URL}' \
    && tar zxvf '${TEMP_DIR}/${TEMP_FILE}' -C '${TEMP_DIR}' \
    && sudo mv  '${TEMP_DIR}/oc' '/usr/local/bin/' \
    && sudo mv  '${TEMP_DIR}/kubectl' '/usr/local/bin/' \
    && rm '${TEMP_DIR}/${TEMP_FILE}' \
    && oc version --client \
    && kubectl version --client \
    "
# TODO    sudo bash -c 'oc completion bash > /etc/bash_completion.d/oc_bash_completion' \


# ccoctl
# https://github.com/okd-project/okd/releases/download/4.14.0-0.okd-2023-12-01-225814/ccoctl-linux-4.14.0-0.okd-2023-12-01-225814.tar.gz
ARG RELEASE_PKG="ccoctl-linux-4.14.0-0.okd-2023-12-01-225814.tar.gz"
ARG INSTALL_URL="${REPO_URL}/${RELEASE_TAG}/${RELEASE_PKG}"
ARG TEMP_DIR="/tmp/ccoctl"
ARG TEMP_FILE="ccoctl-linux.tar.gz"
RUN bash -c "mkdir -p '${TEMP_DIR}' \
    && wget -nv -O '${TEMP_DIR}/${TEMP_FILE}' '${INSTALL_URL}' \
    && tar zxvf '${TEMP_DIR}/${TEMP_FILE}' -C '${TEMP_DIR}' \
    && sudo mv  '${TEMP_DIR}/ccoctl' '/usr/local/bin/' \
    && rm '${TEMP_DIR}/${TEMP_FILE}' \
    && ccoctl help \
    "

# Java
ARG JAVA_SDK="21.0.1-graalce"
RUN bash -c ". /home/gitpod/.sdkman/bin/sdkman-init.sh \
    && sdk install java $JAVA_SDK \
    && sdk default java $JAVA_SDK \
    && sdk install quarkus"

# AWS CLIs
RUN bash -c "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip' && unzip awscliv2.zip \
    && sudo ./aws/install \
    && aws --version \
    "

RUN bash -c "npm install -g aws-cdk"

ARG SAM_URL="https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip"
RUN bash -c "curl -Ls '${SAM_URL}' -o '/tmp/aws-sam-cli-linux-x86_64.zip' \
    && unzip '/tmp/aws-sam-cli-linux-x86_64.zip' -d '/tmp/sam-installation' \
    && sudo '/tmp/sam-installation/install' \
    && sam --version"

RUN bash -c "pip install cloudformation-cli cloudformation-cli-java-plugin cloudformation-cli-go-plugin cloudformation-cli-python-plugin cloudformation-cli-typescript-plugin"

# Done :)
RUN bash -c "echo done."