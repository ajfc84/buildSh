#!/bin/sh


install()
{
    # Repos #
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends \
    curl
    # Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    # MSSQL
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
    # Ansible
    #sudo apt-add-repository ppa:ansible/ansible
    # Dependencies #
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends \
    # Utils
    git jq yq \
    # Docker
    ca-certificates gnupg lsb-release python3-pip \
    # Ansible
    software-properties-common  \
    # MSSQL
    unixodbc-dev
    # Python
    python3 python3-pip python3-venv python3-dev python3-wheel python3-build python3-setuptools
    sudo ln /usr/bin/python3 /usr/bin/python
    pip install build twine # error
    # Requirements #
    # Docker
    apt-get update
    apt-get install -y --no-install-recommends \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    # Java
    default-jre \
    # PostgreSql
    postgresql-client \
    #MSSQL
    mssql-tools18
    # Ansible
    ansible \
    # OpenSSH
    openssh-client openssh-server \
    # Gitlab
    # glab \
    # Docker
    sudo usermod -aG docker $USER
    newgrp docker
}
