# docker build --no-cache --progress=plain -f .gitpod.Dockerfile .
FROM gitpod/workspace-full

# System
# RUN bash -c "sudo install-packages direnv gettext mysql-client gnupg golang"
# RUN bash -c "sudo apt-get update"
# RUN bash -c "sudo pip install --upgrade pip"

# Java
RUN bash -c "source /home/gitpod/.sdkman/bin/sdkman-init.sh \
    && sdk list java | grep -o '[a-zA-Z0-9_\-\.]*-amzn' | head -1 > java.version"
RUN bash -c "source /home/gitpod/.sdkman/bin/sdkman-init.sh \
    && sdk install java $(cat java.version) \
    "

# OpenShift Installer
RUN bash -c "mkdir -p '/tmp/openshift-installer' \
    && wget -nv -O '/tmp/openshift-installer/openshift-install-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-install-linux.tar.gz' \
    && tar zxvf '/tmp/openshift-installer/openshift-install-linux.tar.gz' -C '/tmp/openshift-installer' \
    && sudo mv  '/tmp/openshift-installer/openshift-install' '/usr/local/bin/' \
    && rm '/tmp/openshift-installer/openshift-install-linux.tar.gz'\
    "
    
# Credentials Operator CLI
RUN bash -c "mkdir -p '/tmp/ccoctl' \
    && wget -nv -O '/tmp/ccoctl/ccoctl-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/ccoctl-linux.tar.gz' \
    && tar zxvf '/tmp/ccoctl/ccoctl-linux.tar.gz' -C '/tmp/ccoctl' \
    && sudo mv '/tmp/ccoctl/ccoctl' '/usr/local/bin/' \
    && rm '/tmp/ccoctl/ccoctl-linux.tar.gz'\
    "

# OpenShift CLI
RUN bash -c "mkdir -p '/tmp/oc' \
    && wget -nv -O '/tmp/oc/openshift-client-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-client-linux.tar.gz' \
    && tar zxvf '/tmp/oc/openshift-client-linux.tar.gz' -C '/tmp/oc' \
    && sudo mv '/tmp/oc/oc' '/usr/local/bin/' \
    && sudo mv '/tmp/oc/kubectl' '/usr/local/bin/' \
    && rm '/tmp/oc/openshift-client-linux.tar.gz' \
    "

# Red Hat OpenShift on AWS CLI
RUN bash -c "mkdir -p '/tmp/rosa' \
    && wget -nv -O '/tmp/rosa/rosa-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/rosa/latest/rosa-linux.tar.gz' \
    && tar zxvf '/tmp/rosa/rosa-linux.tar.gz' -C '/tmp/rosa' \
    && sudo mv  '/tmp/rosa/rosa' '/usr/local/bin/' \
    && rm '/tmp/rosa/rosa-linux.tar.gz' \
    "


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
    && sam --version \
    && rm '/tmp/aws-sam-cli-linux-x86_64.zip'"

RUN bash -c "pip install cloudformation-cli cloudformation-cli-java-plugin cloudformation-cli-go-plugin cloudformation-cli-python-plugin cloudformation-cli-typescript-plugin"



RUN bash -c "curl -sLO 'https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_linux_amd64.tar.gz' \
    && tar -xzf eksctl_linux_amd64.tar.gz -C /tmp \
    && rm eksctl_linux_amd64.tar.gz \
    && sudo mv /tmp/eksctl /usr/local/bin \
    "

# Azure CLI
RUN bash -c "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"

# Aliyun CLI
RUN bash -c "brew install aliyun-cli"

# Google CLI
RUN bash -c "curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-437.0.1-linux-x86_64.tar.gz \
    && tar -xf google-cloud-cli-437.0.1-linux-x86_64.tar.gz \
    && rm google-cloud-cli-437.0.1-linux-x86_64.tar.gz \
    && ./google-cloud-sdk/install.sh --quiet \
    && sudo ln -s /workspace/red-pod/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud \
    "

# Oracle Cloud CLI
RUN bash -c "brew install oci-cli"

# Done :)
RUN bash -c "echo 'done.'"

