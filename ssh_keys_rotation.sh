  GNU nano 7.2                                                                                   ssh_keys_rotation.sh
#!/bin/bash

# Check if private instance IP is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <private-instance-ip>"
  exit 1
fi

#
PRIVATE_INSTANCE_IP="$1"

# Paths to old and new keys
OLD_KEY_PATH=~/.ssh/id_rsa
NEW_KEY_PATH=~/.ssh/id_rsa_new
GIT_KEY_PATH=/home/ben/DevOps/INTNetworkingProject_B\github_test_ssh_key.pub



# Generate new SSH key pair
ssh-keygen -t rsa -b 4096 -f $NEW_KEY_PATH -N ""

# Copy new public key to private instance's authorized_keys
scp -i $OLD_KEY_PATH $NEW_KEY_PATH.pub ubuntu@$PRIVATE_INSTANCE_IP:/home/ubuntu/.ssh
ssh -i $OLD_KEY_PATH ubuntu@$PRIVATE_INSTANCE_IP "mkdir -p ~/.ssh && echo $(cat $NEW_KEY_PATH.pub) >> ~/.ssh/authorized_keys"

# Remove old key from authorized_keys on private instance
OLD_PUBLIC_KEY=$(cat $OLD_KEY_PATH.pub)
CLEAR_OLD_KEY=$(echo "$OLD_PUBLIC_KEY" | sed 's/[\/&]/\\&/g')
OLD_PUBLIC_GIT_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBv1ttal/Vch8LJq+7flHKfvzcDgdiYg7Z1MCjqsZK08CLrAfVWLLER/JpTnX8WBXxzmms3yYon2FP4btsjczuXfes1Xd17UUiu4+kLT7DRl9EcAMuJvGMehDjoVnczHChJBIglM+YbgiG7dsE0Rf8CwvijvZ3CAyvZLTfpc4qiDOt55krFe7GZrtRVAo2Kstaw2ptEWO+BPSh+lWVRg1Sai3/jdiXfMN+W9TdILAwFU9gtRVVyMTioPgp0EPgeW2ttf215sZIDDp1oyFfP0ERT87eOY/H2OvzNDAX8Gxqp2OZtdzmnjenWNXmB5JsKT2lGXv/+2vuq/d08Jf/MJmIhsMuYpAVVzBBBE8a/BKxWpa/caCRAfRHHy4KV4SX8PlP9tMaZh+9Jggio0PPRgG9JflnavfnSX5oS8ypvcAPmCqfRJk1PQeWkuuZxRCCUglTnTv30MiH8WuiE3BtrCKt85G68o0D9SvCiJ721fQ3bg7oUvDHR1NhO9VJA8jlnwPRftpmkk82xAybARr+hJH2Qzbsxd4jQI0SQoyTviiKjAFFvhnhlshkkIC5Ikm08Vhnnrqq8FZSl+eSFUm3pJplnldVtT1nuPW/mejnUXLwiXVA3HddukfF8Zyu5LTMW5y5FCrF7ViX9ltVAFBSGR5SrYsGjb8tYZH+U889DDKJ5w== beneytan@gmail.com"
ssh -i $NEW_KEY_PATH ubuntu@$PRIVATE_INSTANCE_IP "sed -i '/$CLEAR_OLD_KEY/d' ~/.ssh/authorized_keys && sed -i '/${OLD_PUBLIC_GIT_KEY}/d' ~/.ssh/authorized_keys"




# Clean up old key if necessary (optional, usually done after verifying access with the new key)
rm -f $OLD_KEY_PATH $OLD_KEY_PATH.pub

# Rename the new key without *_new
mv $NEW_KEY_PATH $HOME/.ssh/id_rsa
mv $NEW_KEY_PATH.pub $HOME/.ssh/id_rsa.pub
echo "A key has been successfully replaced on the local instance."

echo "SSH key rotation ended successfully."