#!/bin/sh
# Relies on clean Ubuntu 16.04
# Exit codes
readonly E_RUN_AS_ROOT='1'
## 1. Enter permanent root
sudo -s

# Check if root
if [ $EUID != '0' ]; then
   echo "ERROR: The \"${SCRIPT_NAME}\" script must be run with root priviliges." 1>&2
   exit "$E_RUN_AS_ROOT"
fi

## 2. Update the system, install curl
apt-get update
apt-get upgrade
apt-get install curl

## 3. Install Docker
curl --ssl -L https://get.docker.com/ | sh

### Enable socket
systemctl enable docker.socket

### 3.a For Ubuntu 16.04: Temporarely install Docker-Compose as a container (because it have ver. >1.6 and easy to remember to change after)
curl --ssl -L https://github.com/docker/compose/releases/download/1.8.1/run.sh > /usr/local/bin/docker-compose

#### Do proper rights:
chown root:docker /usr/local/bin/docker-compose
chmod u+x /usr/local/bin/docker-compose
chmod g+x+r /usr/local/bin/docker-compose # Here +r is just to bash can read it
chmod o-rwx /usr/local/bin/docker-compose
ls -la /usr/local/bin/docker-compose # -rwxr-x--- 1 root docker *** /usr/local/bin/docker-compose*

## 4. Install SaltStack
curl -L https://bootstrap.saltstack.com | sh

### Install SaltStack configuration
mkdir -p /etc/salt/
cp --backup=numbered ./salt/{master,minion} /etc/salt/
mkdir -p /srv/salt/
cp --backup=numbered ./salt/sls/* /srv/salt/
#### Enable/start SlatStack
systemctl start salt-master.service
systemctl enable salt-master.service

systemctl start salt-minion.service
systemctl enable salt-minion.service

#### Accept key
for ((SWITCH=1; SWITCH == 1;;))
do
  salt-key --accept=MaterA --yes
  salt-key --list accepted | grep MasterA
  SWITCH="$?"
done

## Deploy the rest of infrastructure
salt 'MasterA' state.highstate
