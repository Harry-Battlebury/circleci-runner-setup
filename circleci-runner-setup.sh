#!/bin/bash

NAME_SPACE=
VCS_TYPE=
ORG_NAME=
RESOURCE_CLASS=
PERSONAL_API_TOKEN=
CIRCLECI_HOST=
RUNNER_NAME=

# Upgrade os and install dependencies
apt update && apt upgrade -y
apt install -y tar gzip coreutils git

# Install circle-cli
snap install docker
snap install circleci
snap connect circleci:docker docker

# Setup circleci-cli
circleci setup --no-prompt --host $CIRCLECI_HOST --token $PERSONAL_API_TOKEN

# Create circleci namespace (one per organisation)
circleci namespace create --no-prompt $NAME_SPACE $VCS_TYPE $ORG_NAME

# Create a resource class and save its token to $RUNNER_AUTH_TOKEN
RUNNER_AUTH_TOKEN=$(circleci runner resource-class create $NAME_SPACE/$RESOURCE_CLASS "CircleCI Runner" --generate-token | grep auth_token: | cut -c 17-96)

# Download circleci runner installer
export platform=linux/amd64
export base_url="https://circleci-binary-releases.s3.amazonaws.com/circleci-launch-agent"
export agent_version=$(curl "${base_url}/release.txt")

# Set up runner directory
prefix=/opt/circleci
sudo mkdir -p "$prefix/workdir"

# Downloading launch agent
echo "Using CircleCI Launch Agent version $agent_version"
echo "Downloading and verifying CircleCI Launch Agent Binary"
base_url="https://circleci-binary-releases.s3.amazonaws.com/circleci-launch-agent"
curl -sSL "$base_url/$agent_version/checksums.txt" -o checksums.txt
file="$(grep -F "$platform" checksums.txt | cut -d ' ' -f 2 | sed 's/^.//')"
mkdir -p "$platform"
echo "Downloading CircleCI Launch Agent: $file"
curl --compressed -L "$base_url/$agent_version/$file" -o "$file"

# Verifying download
echo "Verifying CircleCI Launch Agent download"
grep "$file" checksums.txt | sha256sum --check && chmod +x "$file"; sudo cp "$file" "$prefix/circleci-launch-agent" || echo "Invalid checksum for CircleCI Launch Agent, please try download again"

# Create runner configuration file
file=/opt/circleci/launch-agent-config.yaml

if [ -f "$file" ] ; then
    rm "$file"
fi

cat << EOF >> /opt/circleci/launch-agent-config.yaml
api:
  auth_token: $RUNNER_AUTH_TOKEN
  # On server, set url to the hostname of your server installation. For example,
  # url: https://circleci.example.com

runner:
  name: $RUNNER_NAME
  command_prefix: ["sudo", "-niHu", "circleci", "--"]
  working_directory: /opt/circleci/workdir/%s
  cleanup_working_directory: true
EOF

# Set permissions runner configuration
chown root: /opt/circleci/launch-agent-config.yaml
chmod 600 /opt/circleci/launch-agent-config.yaml

# Create the circleci user and its working dir
id -u circleci &>/dev/null || adduser --disabled-password --gecos GECOS circleci

mkdir -p /opt/circleci/workdir
chown -R circleci /opt/circleci/workdir

# Create circleci runner service
file=/opt/circleci/circleci.service

if [ -f "$file" ] ; then
    rm "$file"
fi

cat << EOF >> /opt/circleci/circleci.service
[Unit]
Description=CircleCI Runner
After=network.target
[Service]
ExecStart=/opt/circleci/circleci-launch-agent --config /opt/circleci/launch-agent-config.yaml
Restart=always
User=root
NotifyAccess=exec
TimeoutStopSec=18300
[Install]
WantedBy = multi-user.target
EOF

# Set permissions of circleci service
chown root: /opt/circleci/circleci.service
chmod 755 /opt/circleci/circleci.service

# Enable and start circleci runner service
systemctl enable /opt/circleci/circleci.service
systemctl start circleci.service
systemctl status circleci.service --no-pager