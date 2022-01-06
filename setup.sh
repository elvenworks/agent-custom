#!/usr/bin/env bash
OS_NAME=$(cat /etc/os-release | awk -F '=' '/^NAME/{print $2}' | awk '{print $1}' | tr -d '"')
TIME=1
clear


InstallAgent(){
    ### Create Systemd Agent
    echo "Installing 1P Agent"
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
      Environment=$AGENT_TOKEN

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

    ### Set Version Agent And Script Update
    echo "Create Update Script"
    curl -sI https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent | grep x-amz-meta-version >${PWD}/agent-version-installed
    crontab "${PWD}/scripts/crontab-source"

    ### Start Agent 1P
    echo "Start 1P Agent"
    service 1p-agent start

    ### check success to start the agent
    if [ $? -eq 0 ]; then
        echo "Agent 1P running"
    else
        echo "Error On Start 1P Agent"
        exit 1
    fi

    ### End installation
    echo "Agent installed"
    sleep $TIME
    exit 0
}


UpdateAgentConfigs(){
    echo "Updating 1P Agent"
    service 1p-agent stop
    if [ $? -eq 0 ]; then
        echo "1P Agent Stopped"
    else
        echo "Error On Stopping 1P Agent"
        exit 1
    fi
    ### Update Systemd Agent
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
      Environment=$AGENT_TOKEN

      [Install]
      WantedBy=multi-user.target
EOF
    ### move config
    mv 1p-agent.service /etc/systemd/system
    systemctl daemon-reload
    if [ $? -eq 0 ]; then
        echo "Reloading Complete"
    else
        echo "Reloading Error"
        exit 1
    fi
    ### Start 1P Agent
    echo "Start 1P Agent"
    service 1p-agent start

    ### Check success to start the agent
    if [ $? -eq 0 ]; then
        echo "1P Agent running"
    else
        echo "Error On Start 1P Agent"
        exit 1
    fi
    ### End installation
    echo "Agent Updated"
    sleep $TIME
    exit 0   
}

UninstallAgent(){
    echo "Deleting 1P Agent"
    ### stop 1p agent
    service 1p-agent stop
    ### delete config 1p agent
    rm /etc/systemd/system/1p-agent.service
    ### delete bin 1p agent
    rm /usr/bin/1p-agent
    ### reload system
    systemctl daemon-reload
    ### delete user
    sleep $TIME
    case $OS_NAME in
    Amazon | CentOS)
        userdel -r 1p-agent
    ;;
    Ubuntu)
        deluser --remove-home elvenworks
    ;;
    esac  
    echo "1P Agent Deleted"
    exit 0
}

UpdateLogsAgent(){
    echo "Update 1P Agent"
    ### remove config rsyslog user
    sleep $TIME
    rm -vrf /etc/rsyslog.d/22-logzio-linux.conf
    systemctl restart rsyslog
    echo "Done"
    exit 0
}


CheckSetEnvironments(){
echo "Check Enviroments"
sleep $TIME
if  [ -z $1 ] || [ -z $2 ] ; then
    echo "Please Set ENVIRONMENT_ID And AGENT_TOKEN"
    exit 1
else
    ENVIRONMENT_ID=$1
    AGENT_TOKEN=$2
fi
}

ConfigOS(){
case $OS_NAME in
Amazon | CentOS)
    ### Create User 1p-agent
    echo "Create User"
    sleep $TIME
    adduser 1p-agent --uid 1950
    ### Disable SeLinux
    setenforce 0
    sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
    ### Set User
    USER=1950
    ;;
Ubuntu)
    ### Create User elvenworks
    echo "Create User"
    sleep $TIME
    adduser --gecos "" --disabled-password elvenworks
    ### Set User
    USER=elvenworks
    ;;
esac  
}

case $1 in
--install)
    ### Install 1P Agent
    ConfigOS
    CheckSetEnvironments $2 $3
    InstallAgent
    ;;
--update)
    ### Update Configs
    CheckSetEnvironments $2 $3
    UpdateAgentConfigs
    ;;
--uninstall)
    ### Delete 1P Agent
    UninstallAgent
    ;;    
--updatelogs) ## Is a TMP action
    ### Update Logs Configs
    UpdateLogsAgent
    ;;
*)
    echo "Please Set Your Option"
    echo " "
    echo "--install to install 1p-agent"
    echo " "
    echo "--update to update 1p-agent "
    echo " "
    echo "--uninstall to delete 1p-agent"
    exit 1
    ;;
esac
