#!/bin/bash
#set -x

#Baixando container atualizado
pull=`sudo /usr/bin/docker pull elvenworks/1p-agent | grep 'Status: Image is up to date for docker.io' | wc -l`
if [ $pull == 1 ] ; then echo "Esta atualizado" && exit 0;
fi

#Remove docker atual
atualiza=`/usr/bin/docker ps |grep elvenworks | awk '{print $1}'`
for i in $atualiza; do 
	/usr/bin/docker stop $i && /usr/bin/docker rm $i -f && echo "Removido o container $i"
done

#PRD
export env ENVIRONMENT_ID=<ENV ID>
export env DOCKER_IMAGE_VERSION=latest
/usr/bin/docker run -d -e DB_CONN="sqlite" -e DB_HOST="localhost" -e ENVIRONMENT_ID=$ENVIRONMENT_ID -e NATS_HOST=<NATS_HOST> -e NATS_USER=<NATS_USER> -e NATS_PASS=<NATS_PASS> elvenworks/1p-agent

#Subi
echo "Atualizei o docker"
docker ps -a |grep elvenworks
