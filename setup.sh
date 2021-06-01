#!/usr/bin/env bash
OS_NAME=$(cat /etc/os-release | awk -F '=' '/^NAME/{print $2}' | awk '{print $1}' | tr -d '"')
TIME=1
clear

echo "Check Variables"
sleep $TIME
if [ -z "$1" ]; then
    echo "Please ENVIRONMENT_ID"
    exit 1
else
    ENVIRONMENT_ID=$1
fi

commonInstallation() {
    ### Create Systemd Agent
    echo "Installing Agent 1P"
    cat <<EOF >1p-agent.service
    [Unit]
    Description=1p-agent is a component of Elven Works One Platform.
    After=network.target
    StartLimitIntervalSec=500
    StartLimitBurst=5

    [Service]
    Restart=on-failure
    RestartSec=5s
  
    User=$USER
    ExecStart=/usr/bin/1p-agent
    Environment=PORT=8080
    Environment=$ENVIRONMENT_ID
                
    [Install]
    WantedBy=multi-user.target
EOF
    mv 1p-agent.service /etc/systemd/system
    systemctl enable 1p-agent
    curl -sLO https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent
    chmod +x 1p-agent
    mv 1p-agent /usr/bin/

    ### Set Eip Permission
    setcap cap_net_raw,cap_net_admin=eip /usr/bin/1p-agent

    ### Start Agent 1P
    echo "Start Agent 1P"
    service 1p-agent start

    ### check success to start the agent
    if [ $? -eq 0 ]; then
        echo "Agent 1P running"
    else
        echo "Error On Start Agent 1P"
        exit 1
    fi

    ### Set Logs
    echo "Setup Logz"
    curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz
    tar xzf logzio-rsyslog.tar.gz
    sed -i '95 s/./} -w 2/52' rsyslog/configure_linux.sh
    source /tmp/logzio_env_token
    yes | sudo rsyslog/install.sh -t linux -a $LOGZIO_TOKEN -l "listener.logz.io"
    rm -vrf /tmp/logzio_env_token

    ### Set Version Agent And Script Update
    echo "Create Update Script"
    curl -sI https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent | grep x-amz-meta-version >${PWD}/agent-version-installed
    crontab "${PWD}/scripts/crontab-source"

    ### End installation
    echo "Agent installed"
    sleep $TIME
    exit 0

}

case $OS_NAME in
Amazon | CentOS)
    ### Create User 1p-agent
    echo "Create User"
    sleep $TIME
    adduser 1p-agent
    ### Disable SeLinux
    setenforce 0
    sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
    ### Uninstall Telnet
    echo "Check Telnet installed"
    if ls /usr/bin/telnet; then
        yum remove telnet -y
    fi
    ### Set User
    USER=1p-agent
    ### Call Common Function
    commonInstallation
    ;;
Ubuntu)
    ### Create User elvenworks
    echo "Create User"
    sleep $TIME
    adduser --gecos "" --disabled-password elvenworks
    ### Uninstall Telnet
    echo "Check Telnet installed"
    if ls /usr/bin/telnet; then
        apt-get remove telnet -y
    fi
    ### Set User
    USER=elvenworks
    ### Call Common Function
    commonInstallation
    ;;
esac
# done
