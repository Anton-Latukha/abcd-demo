#!/bin/sh
# Relies on clean Ubuntu 16.04
readonly SCRIPT_NAME="$(basename "$0")"
# Exit codes
readonly E_RUN_AS_ROOT='1'

## 1. Check if root
if test "$(id -u)" -ne '0'; then
   echo "ERROR: The \"${SCRIPT_NAME}\" script must be run with root priviliges." 1>&2
   exit "$E_RUN_AS_ROOT"
fi

## 2. Update the system, install curl
apt-get update
apt-get upgrade
apt-get install curl

## 3. Install Docker
curl --ssl -L https://get.docker.com/ | sh

### Enable Docker socket
systemctl enable docker.socket

### 3.a For Ubuntu 16.04: Temporarely install Docker-Compose as a container (because we going to have ver. >1.6 which is required for Version 2)
curl --ssl -L https://github.com/docker/compose/releases/download/1.8.1/run.sh > /usr/local/bin/docker-compose

#### Do proper rights:
chown root:docker /usr/local/bin/docker-compose
chmod u+x /usr/local/bin/docker-compose
chmod g+x+r /usr/local/bin/docker-compose # Here +r is just to bash can read it
chmod o-rwx /usr/local/bin/docker-compose
ls -la /usr/local/bin/docker-compose # -rwxr-x--- 1 root docker *** /usr/local/bin/docker-compose*

## 4. Install SaltStack
curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com
sh /tmp/bootstrap-salt.sh -M -P -A 127.0.0.1 -i MasterA  # Means "also master"

### Install SaltStack configuration
mkdir -p /etc/salt/
cp --backup=numbered ./salt/master /etc/salt/
cp --backup=numbered ./salt/minion /etc/salt/
mkdir -p /srv/salt/
cp --backup=numbered ./salt/sls/* /srv/salt/

#### Stop/Enable/Start SlatStack
systemctl stop salt-master.service
systemctl start salt-master.service
systemctl enable salt-master.service

systemctl stop salt-minion.service
systemctl start salt-minion.service
systemctl enable salt-minion.service

#### Accept key
RESULT=1
while test "$RESULT" -ne '0' # Watch for key until it accepted and Zero returned
do
  salt-key --accept=MasterA --yes
  salt-key --list accepted | grep MasterA
  RESULT="$?"
done

#### Wait for Master-Minion get ready
RESULT=1
while test "$RESULT" -ne '0' # Wait till Minion runs a commands and Zero returned
do
  salt --failhard --verbose --timeout=60 'MasterA' test.ping
  RESULT="$?"
done

## 5. Now deploy the rest of infrastructure with SaltStack
salt 'MasterA' state.highstate
