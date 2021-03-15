#!/usr/bin/env bash
#set -x

VERSION_INSTALLED=`cat /root/agent-custom/agent-version-installed`
VERSION_CURRENT=`curl -sI https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent  |grep x-amz-meta-version`


if [ "$VERSION_INSTALLED" != "$VERSION_CURRENT" ]; then
	echo "Stop Agent 1P"
    service 1p-agent stop

	echo "Agent 1P Update"
	rm -r  /usr/bin/1p-agent
	curl -sLO https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent
	chmod +x 1p-agent
    mv 1p-agent /usr/bin/

    echo "Start Agent 1P"
    service 1p-agent start

	echo "Set Version Installed"
	curl -sI https://1p-installers.s3.amazonaws.com/agent/bin/linux/latest/1p-agent  |grep x-amz-meta-version >> /root/agent-custom/agent-version-installed
else
    echo "No Updates"
fi