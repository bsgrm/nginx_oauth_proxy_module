#!/bin/bash

###################################################################################
# Build and deploy one of the supported Linux distributions with the shared module
###################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

export ENCRYPTION_KEY=$(openssl rand 32 | xxd -p -c 64)
echo -n $ENCRYPTION_KEY > encryption.key

# Validate input for the distro
DISTRO=$1
case $DISTRO in

  'alpine')
    MODULE_PREFIX='alpine'
    ;;

  'ubuntu18')
    MODULE_PREFIX='ubuntu.18.04'
    ;;
esac

if [ "$MODULE_PREFIX" == '' ]; then
  echo 'Please enter a supported Linux distribution as a command line argument'
  exit
fi

# Build the Docker image
echo 'Building the NGINX and valgrind Docker image ...'
docker build --no-cache -f "$DISTRO/Dockerfile" -t "nginx_$DISTRO":v1 .
if [ $? -ne 0 ]; then
  echo "Problem encountered building the NGINX $DISTRO docker image"
  exit 1
fi

# Supply a runtime 32 byte AES256 cookie encryption key
export ENCRYPTION_KEY=$(openssl rand 32 | xxd -p -c 64)
echo -n $ENCRYPTION_KEY > encryption.key

# Update the runtime configuration file
NGINX_CONF_DATA=$(cat ./nginx.conf.template)
NGINX_CONF_DATA=$(sed "s/ENCRYPTION_KEY/$ENCRYPTION_KEY/g" <<< "$NGINX_CONF_DATA")
echo "$NGINX_CONF_DATA" > ./nginx.conf

# Deploy the Docker container for the distro
echo 'Deploying the NGINX and valgrind Docker image ...'
export DISTRO
export MODULE_PREFIX
export ENCRYPTION_KEY
docker-compose up --force-recreate --remove-orphans
if [ $? -ne 0 ]; then
  echo "Problem encountered building the NGINX $DISTRO docker image"
  exit 1
fi
