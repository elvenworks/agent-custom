# agent-custom
Setup Agent Custom 1p
## Prerequisites

You will need the following things properly configured.

- [1P Account](https://1p.elven.works/products)
- [Cloud Custom](https://1p.elven.works/clouds/new)
- [Git](http://git-scm.com/)

Operational System

- Amazon Linux 2 Or CentOS 7 
## Installation

- `sudo su -`
- `yum install git -y` 
- `git clone https://github.com/elvenworks/agent-custom.git` this repository
- `cd agent-custom`
- `bash setup.sh ENVIRONMENT_ID=my-env-id`




## Installation Ubuntu

- `sudo su -`
- `apt-get install git -y` 
- `git clone https://github.com/elvenworks/agent-custom.git` this repository
- `cd agent-custom`
- `bash setup.sh ENVIRONMENT_ID=my-env-id`

## Check Setup

- `systemctl status 1p-agent.service`