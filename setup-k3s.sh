#!/bin/sh

check_arguments() {
  # Check number of arguments
  if [ $# -ne 1 ]; then
    echo "Please provide exactly one argument, the token"
    exit 1
  fi

  ARG=$1
#   # Check for two colons
#   if echo "$ARG" | grep -q "::"; then
#     echo "Detected full output from 'k3s token create', only using creds"
#     ARG=$(echo "$ARG" | sed 's/.*:://')
#   fi

  echo secret is $ARG

  # Rest of the script, using $ARG
  curl -sfL https://get.k3s.io | K3S_TOKEN=$ARG sh -s - server --server https://10.10.1.2:6443
}

# Call the function with all script arguments
check_arguments "$@"
