#!/bin/bash

function check_root() {
      set -e
      if [ "$EUID" -ne 0 ]; then
            echo "Please run as root"
            exit
      fi
}

function expect_geoff_disk() {
      set -e
      if [ -z "$GEOFF_DISK" ]; then
            echo "Error: DISK environment variable is not set."
            exit 1
      fi
}

function expect_geoff_creds() {
      set -e
      if [ -z "$GEOFF_K3S_SERVER" ]; then
            echo "Error: \$GEOFF_K3S_SERVER variable is not set."
            exit 1
      fi

      if [ -z "$GEOFF_K3S_TOKEN" ]; then
            echo "Error: \$GEOFF_K3S_TOKEN variable is not set."
            exit 1
      fi
}

function parse_creds() {
      set -e
      # Parse command line arguments
      while [[ $# -gt 0 ]]; do
            key="$1"
            case $key in
            --geoff-k3s-server)
                  if [ ! -z "$GEOFF_K3S_SERVER" ] && [ "$GEOFF_K3S_SERVER" != "$2" ]; then
                        echo "Error: Environment variable GEOFF_K3S_SERVER ($GEOFF_K3S_SERVER) does not match CLI argument ($2)"
                        exit 1
                  fi

                  GEOFF_K3S_SERVER="$2"
                  shift # past argument
                  shift # past value
                  ;;
            --geoff-k3s-token)
                  if [ ! -z "$GEOFF_K3S_TOKEN" ] && [ "$GEOFF_K3S_TOKEN" != "$2" ]; then
                        echo "Error: Environment variable GEOFF_K3S_TOKEN ($GEOFF_K3S_TOKEN) does not match CLI argument ($2)"
                        exit 1
                  fi

                  GEOFF_K3S_TOKEN="$2"
                  shift # past argument
                  shift # past value
                  ;;
            *) # unknown option
                  echo "Unknown option: $key"
                  exit 1
                  ;;
            esac
      done

      export GEOFF_K3S_SERVER
      export GEOFF_K3S_TOKEN
}
