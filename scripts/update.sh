#!/usr/bin/env bash
#set -x

VERSION_INSTALLED=`cat /root/agent-custom/agent-version-installed`
VERSION_CURRENT=`curl -sI https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent  |grep x-amz-meta-version`
TIME=1

if [ "$VERSION_INSTALLED" != "$VERSION_CURRENT" ]; then
	echo "Stop Agent 1P"
    systemctl stop 1p-agent.service
	sleep $TIME

	echo "Agent 1P Update"
	rm -r  /usr/bin/1p-agent
	curl -sLO https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent
	chmod +x 1p-agent
    mv 1p-agent /usr/bin/

    echo "Start Agent 1P"
	sleep $TIME
    systemctl start 1p-agent.service

	echo "Set Version Installed"
	curl -sI https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent  |grep x-amz-meta-version > /root/agent-custom/agent-version-installed
else
    echo "No Updates"
fi