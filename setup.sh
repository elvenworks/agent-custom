#!/usr/bin/env bash
OS_NAME=$(cat /etc/os-release | awk -F '=' '/^NAME/{print $2}' | awk '{print $1}' | tr -d '"')
TIME=1
clear

case 1 in
        1)
                echo "Check Variables"
                sleep $TIME
                if [ -z "$1" ]; then
                 echo "Please ENVIRONMENT_ID"
                 exit 1
                else
                 ENVIRONMENT_ID=$1
                fi
                echo "Check OS"
                sleep $TIME
                if [ "$OS_NAME" == "CentOS" ] ; then
                 echo "Is $OS_NAME"
                elif [ "$OS_NAME" == "Amazon" ]; then
                 echo "Is $OS_NAME"
                else
                 echo "OS Not Supported"
                 exit 1
                fi
                adduser 1p-agent
                echo "Installing Agent 1P"
                cat <<EOF > 1p-agent.service
                [Unit]
                Description=1p-agent is a component of Elven Works One Platform.
                After=network.target
                StartLimitIntervalSec=500
                StartLimitBurst=5

                [Service]
                Restart=on-failure
                RestartSec=5s
  
                User=1p-agent
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
                
                setenforce 0 ; 
                sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux 

                setcap cap_net_raw,cap_net_admin=eip /usr/bin/1p-agent

                echo "Start Agent 1P"
                service 1p-agent start

                echo "Check Telnet installed"
                if ls /usr/bin/telnet ; then
                    yum remove telnet -y 
                fi

                echo "Setup Logz"
                curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz
                tar xzf logzio-rsyslog.tar.gz
                source /tmp/logzio_env_token
                yes | sudo rsyslog/install.sh -t linux -a $LOGZIO_TOKEN -l "listener.logz.io"
                rm -vrf /tmp/logzio_env_token

                echo "Create Update Script"
                curl -sI https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent  |grep x-amz-meta-version > /root/agent-custom/agent-version-installed
                crontab "/root/agent-custom/scripts/crontab-source"
                
                echo "Agent installed"
                sleep $TIME
                
                exit 0
                ;;
esac
done