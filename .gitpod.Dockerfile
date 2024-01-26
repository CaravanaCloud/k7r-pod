# docker build --no-cache --progress=plain -f .gitpod.Dockerfile .
FROM gitpod/workspace-full

# GitPod System
RUN bash -c "sudo install-packages direnv gettext mysql-client gnupg golang"
RUN bash -c "sudo apt-get update"
RUN bash -c "sudo pip install --upgrade pip"

RUN bash -c "brew install helm"

# AWS CLIs
ARG AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
RUN bash -c "curl '${AWS_URL}' -o 'awscliv2.zip' \
    && unzip awscliv2.zip \
    && sudo ./aws/install \
    && aws --version \
    && rm -f awscliv2.zip \
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