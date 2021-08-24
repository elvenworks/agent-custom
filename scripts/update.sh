#!/usr/bin/env bash
#set -x

VERSION_INSTALLED=`cat /root/agent-custom/agent-version-installed`
VERSION_CURRENT=`curl -sI https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent  |grep x-amz-meta-version`
TIME=1

if [ "$VERSION_INSTALLED" != "$VERSION_CURRENT" ]; then
	echo "Start Update 1P Agent"
	if curl -sLO https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent	; then
		echo "Stop 1P Agent"
    	systemctl stop 1p-agent.service
		sleep $TIME
		chmod +x 1p-agent
		rm -r  /usr/bin/1p-agent
		mv 1p-agent /usr/bin/
		echo "Set Version Installed"
		echo $VERSION_CURRENT > /root/agent-custom/agent-version-installed
		sleep $TIME
		echo "Start 1P Agent"
		sleep $TIME
		systemctl start 1p-agent.service
    else
		echo "Error On Update 1P Agent"
		exit 1
	fi
else
    echo "No Updates"
fi