#!/bin/bash

# Check if the KEY_PATH environment variable is set
if [ -z "$KEY_PATH" ]; then
    echo "KEY_PATH env var is expected"
    exit 5
fi

# Check if at least one argument is provided (public instance IP)
if [ $# -lt 1 ]; then
    echo "Please provide bastion IP address"
    exit 5
fi

# Assign variables based on provided arguments
PUBLIC_IP=$1
PRIVATE_IP=$2
REMOTE_COMMAND=$3

# Check if private IP is provided
if [ -z "$PRIVATE_IP" ]; then
    # Connect to the public instance (bastion host)
    ssh -i "$KEY_PATH" ubuntu@"$PUBLIC_IP"
else
    # Connect to the private instance through the bastion host
    if [ -z "$REMOTE_COMMAND" ]; then
        # If no command is provided, establish an interactive SSH session
        ssh -i "$KEY_PATH" -o ProxyCommand="ssh -i $KEY_PATH -W %h:%p ubuntu@$PUBLIC_IP" ubuntu@$PRIVATE_IP
    else
        # If a command is provided, execute it on the private instance
        ssh -i "$KEY_PATH" -o ProxyCommand="ssh -i $KEY_PATH -W %h:%p ubuntu@$PUBLIC_IP" ubuntu@$PRIVATE_IP "$REMOTE_COMMAND"
    fi
fi

