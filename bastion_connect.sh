#!/bin/bash

# Check if KEY_PATH is set
if [ -z "$KEY_PATH" ]; then
  echo "KEY_PATH env var is expected"
  exit 5
fi

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
  echo "Please provide bastion IP address"
  exit 5
fi

# Assign input arguments
BASTION_IP=$1
PRIVATE_IP=$2
COMMAND=${@:3}

# If a private IP is provided, connect to the private instance via the bastion host
if [ -n "$PRIVATE_IP" ]; then
  if [ -n "$COMMAND" ]; then
    ssh -i "$KEY_PATH" -o ProxyCommand="ssh -i $KEY_PATH -W %h:%p ubuntu@$BASTION_IP" ubuntu@$PRIVATE_IP $COMMAND
  else
    ssh -i "$KEY_PATH" -o ProxyCommand="ssh -i $KEY_PATH -W %h:%p ubuntu@$BASTION_IP" ubuntu@$PRIVATE_IP
  fi
else
  # If no private IP is provided, connect to the bastion host
  ssh -i "$KEY_PATH" ubuntu@$BASTION_IP
fi
