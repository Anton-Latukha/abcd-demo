#!/bin/sh
## Solving chicken and an egg problem. Hot to get SaltStack infrastructure on a clean system. - With a script.
## Using shell Docker installation as a much more simpler solution. In Salt, as it is going to be more hustle. To add Docker formula to Salt and then also new composer through elegant hack, then to do it through shell once. And then manage already installed Docker.
# Relies on clean Ubuntu 16.04
readonly SCRIPT_NAME="$(basename "$0")"
# Exit codes
readonly E_RUN_AS_ROOT='1'

## 1. Check if root privileges available
if test "$(id -u)" -ne '0'; then
   echo "ERROR: The \"${SCRIPT_NAME}\" script must be run with root privileges" 1>&2
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

### 3.a For Ubuntu 16.04: Temporarily install Docker-Compose as a container (because we going to have ver. >1.6 which is required for Version 2, and SaltStack)
curl --ssl -L https://github.com/docker/compose/releases/download/1.8.1/run.sh > /usr/local/bin/docker-compose

#### Do proper rights:
chown root:docker /usr/local/bin/docker-compose
chmod u+x /usr/local/bin/docker-compose
chmod g+x+r /usr/local/bin/docker-compose # Here +r is just to bash can read it
chmod o-rwx /usr/local/bin/docker-compose
ls -la /usr/local/bin/docker-compose    # -rwxr-x--- 1 root docker *** /usr/local/bin/docker-compose*

## 4. Install SaltStack
curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com
sh /tmp/bootstrap-salt.sh -M -P -A 127.0.0.1 -i MasterA  # Means "also master"

: '
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
'

### Accept local Minion key
RETURN=1
echo 'Please wait for Master and minion to get ready. It can take couple of minutes...'
while test "$RETURN" -ne '0'    # Watch for key until it accepted and Zero returned
do
  echo 'Waiting a Minion key to appear...'
  salt-key --accept='MasterA' --yes
  salt-key --list accepted | grep MasterA
  RETURN="$?"
done

echo 'Key found and accepted.'

### Get Master-Minion ready
sleep 5    # Wait Minion to get & process acceptance message
RETURN=1
while test "$RETURN" -ne '0'    # Wait till Minion runs a command and Zero returned
do
  salt --failhard --verbose --timeout=240 'MasterA' test.ping
  RETURN="$?"
done

echo 'Minion is ready.'

## 5. Now everything is ready to deploy the rest of infrastructure with SaltStack
salt 'MasterA' state.highstate
