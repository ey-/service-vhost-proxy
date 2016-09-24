#!/bin/sh

if [[ "$SUPERVISOR_DEBUG" -gt "0" ]]; then
  echo "SUPERVISOR DEBUG"
  set -x
fi

if [[ "$1" != "" && -f "$1" ]]; then
  export COMPOSE_FILE="$1"

  local LOCK_FILE="$(dirname $COMPOSE_FILE)/.lock"

  if [[ ! -f "$LOCK_FILE" ]]; then
    echo "Creating lockfile $LOCK_FILE"
    touch "$LOCK_FILE"

    # Figure out the default project network name
    # TODO: refactor into something less hacky
    #local network="$(/usr/local/bin/docker-compose ps cli | awk 'NR==3 {print $1}' | sed 's/_cli_1//')_default"
    # Docker Compose project name is an alphanumeric string derived from the directory name
    local network="$(echo $(basename $(dirname $COMPOSE_FILE)) | sed 's/[^[:alnum:]]*//g')_default"
    /usr/local/bin/docker network connect "$network" vhost-proxy 2>&1
    # Restart services if vhost-proxy was connected (first time) to the project network
    # TODO: figure out how to avoid doing a restart
    if [[ $? == 0 ]]; then
      echo "Connected vhost-proxy to \"${network}\" network."
      # Restart to trigger docker-gen to regenerate nginx config
      /usr/local/bin/docker-compose restart
    else
      # Start containers
      /usr/local/bin/docker-compose start
    fi

    echo "Removing lockfile $LOCK_FILE"
    rm -rf "$LOCK_FILE"
    exit 0
  else
    echo "Project is locked with lockfile $LOCK_FILE"
    exit 1
  fi
fi
exit 1