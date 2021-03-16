#!/usr/bin/env bash
TIME=1
clear
while true;do
echo " "
echo "Welcome, Choose An Option!
      1 - Install Agent 1P
      2 - Force Agent 1P Update
      0 - Exit Install"
echo " "
echo -n "The option chosen: "
read option
case $option in
        1)
                echo "Check Variables"
                sleep $TIME
                if [ -z "$1" ] || [ -z "$2" ] ; then
                 echo "Please ENVIRONMENT_ID And LOGZIO_TOKEN"
                 exit 1
                elif [[ $1 == *'ENVIRONMENT_ID='* ]]; then
                 ENVIRONMENT_ID=$1
                 LOGZIO_TOKEN=$2
                else
                 LOGZIO_TOKEN=$1
                 ENVIRONMENT_ID=$2
                fi
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
  
                User=ec2-user
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

                echo "Setup Logz"
                curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz
                tar xzf logzio-rsyslog.tar.gz
                yes | sudo rsyslog/install.sh -t linux -a $LOGZIO_TOKEN -l "listener.logz.io"
                
                echo "Start Agent 1P"
                service 1p-agent start

                echo "Create Update Script"
                curl -sI https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent  |grep x-amz-meta-version > /root/agent-custom/agent-version-installed
                crontab "/root/agent-custom/scripts/crontab-source"
                
                echo "Agent installed"
                sleep $TIME
                
                exit 0
                ;;
        2)
                echo "Stop Agent 1P"
                service 1p-agent stop

                echo "Force Agent 1P Update"
                rm -r  /usr/bin/1p-agent
                curl -sLO https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent
                chmod +x 1p-agent
                mv 1p-agent /usr/bin/

                echo "Start Agent 1P"
                service 1p-agent start
                sleep $TIME
                exit 0
                ;;
        0)
                echo Exit...
                sleep $TIME
                exit 0
                ;;
esac
done