#!/bin/bash

# Check if the server IP is provided
if [ -z "$1" ]; then
  echo "Usage: bash tlsHandshake.sh <server_ip>"
  exit 1
fi

SERVER_IP=$1
CA_CERT_URL="https://exit-zero-academy.github.io/DevOpsTheHardWayAssets/networking_project/cert-ca-aws.pem"
CA_CERT_FILE="cert-ca-aws.pem"
SERVER_CERT_FILE="server_cert.pem"
MASTER_KEY_FILE="master_key.bin"
ENCRYPTED_MASTER_KEY_FILE="encrypted_master_key.der"
DECRYPTED_SAMPLE_FILE="decrypted_sample.txt"
SAMPLE_MESSAGE="Hi server, please encrypt me and send to client!"
EXPECTED_SAMPLE_MESSAGE="Hi server, please encrypt me and send to client!"

# Step 1: Client Hello
echo "Sending Client Hello to the server..."
CLIENT_HELLO_RESPONSE=$(curl -s -X POST http://$SERVER_IP:8080/clienthello -H "Content-Type: application/json" -d '{
   "version": "1.3",
   "ciphersSuites": [
      "TLS_AES_128_GCM_SHA256",
      "TLS_CHACHA20_POLY1305_SHA256"
   ],
   "message": "Client Hello"
}')

# Check if the Client Hello response is empty or contains an error
if [ -z "$CLIENT_HELLO_RESPONSE" ]; then
  echo "Failed to receive Server Hello."
  exit 2
fi

echo "Received Server Hello response."

# Step 2: Parse Server Hello
echo "Parsing Server Hello..."
SESSION_ID=$(echo $CLIENT_HELLO_RESPONSE | jq -r '.sessionID')
SERVER_CERT=$(echo $CLIENT_HELLO_RESPONSE | jq -r '.serverCert')

# Save the server certificate to a file
echo "$SERVER_CERT" > $SERVER_CERT_FILE

echo "Session ID: $SESSION_ID"
echo "Server certificate saved to $SERVER_CERT_FILE."

# Step 3: Server Certificate Verification
echo "Downloading CA certificate..."
wget -q $CA_CERT_URL -O $CA_CERT_FILE

echo "Verifying server certificate..."
openssl verify -CAfile $CA_CERT_FILE $SERVER_CERT_FILE
if [ $? -ne 0 ]; then
  echo "Server Certificate is invalid."
  exit 5
fi
echo "Server certificate is valid."

# Step 4: Client-Server master-key exchange
echo "Generating a random master key..."
openssl rand -base64 32 > $MASTER_KEY_FILE

echo "Encrypting the master key using the server's certificate..."
openssl smime -encrypt -aes-256-cbc -in $MASTER_KEY_FILE -outform DER $SERVER_CERT_FILE > $ENCRYPTED_MASTER_KEY_FILE

# Read the encrypted master key
ENCRYPTED_MASTER_KEY=$(base64 -w 0 $ENCRYPTED_MASTER_KEY_FILE)

echo "Sending the encrypted master key to the server..."
KEY_EXCHANGE_RESPONSE=$(curl -s -X POST http://$SERVER_IP:8080/keyexchange -H "Content-Type: application/json" -d '{
    "sessionID": "'"$SESSION_ID"'",
    "masterKey": "'"$ENCRYPTED_MASTER_KEY"'",
    "sampleMessage": "'"$SAMPLE_MESSAGE"'"
}')

# Step 5: Server verification message
echo "Parsing server's encrypted sample message..."
ENCRYPTED_SAMPLE_MESSAGE=$(echo $KEY_EXCHANGE_RESPONSE | jq -r '.encryptedSampleMessage')

# Decode the base64-encoded encrypted sample message
echo "$ENCRYPTED_SAMPLE_MESSAGE" | base64 -d > $DECRYPTED_SAMPLE_FILE

# Decrypt the sample message using the master key
DECRYPTED_SAMPLE_MESSAGE=$(openssl enc -d -aes-256-cbc -pbkdf2 -in $DECRYPTED_SAMPLE_FILE -k $(cat $MASTER_KEY_FILE))

# Step 6: Client verification message
if [ "$DECRYPTED_SAMPLE_MESSAGE" != "$EXPECTED_SAMPLE_MESSAGE" ]; then
  echo "Server symmetric encryption using the exchanged master-key has failed."
  exit 6
fi

echo "Client-Server TLS handshake has been completed successfully."
