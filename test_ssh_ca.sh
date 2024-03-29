# Enter Environment & Id Token given by CA Authentication
read -p "Enter Environment:-" environment
read -p "Enter Id Token:-" id_token

# This will go into docker /etc/ssh/-> and used to get signed cert
environment_public_key=$(curl https://ssh-management-server.herokuapp.com/v1/environments?uuid=1cda7e65-2619-4de8-bdf4-d2439c62a2eb | jq -r '.result | .[] | .public_key')
environment_name=$(curl https://ssh-management-server.herokuapp.com/v1/environments?uuid=1cda7e65-2619-4de8-bdf4-d2439c62a2eb | jq -r '.result | .[] | .name')
url="https://ssh-management-server.herokuapp.com/v1/user_certs/${environment}/${id_token}"

# Setting environment which will go into client. 
echo $environment_public_key > ./ssh/users_ca.pub
# Send our principals, public key and get it signed with environment private key
# Pull out the signed certificate and put it in our ~/.ssh/
signed_certificate=$(curl -H "Content-Type": "application/json" $url | jq -r '.result | .user_cert | .[-1] | .signed_cert')
echo $signed_certificate
sudo echo $signed_certificate > ~/.ssh/id_rsa-cert.pub

# Build and run the docker image
sudo docker build --rm -f "Dockerfile" -t ssh-ca-cert:latest .
sudo docker stop ssh-ca-cert-run-1
sudo docker run --rm -d -p 2201:22/tcp --name ssh-ca-cert-run-1 ssh-ca-cert:latest
sudo docker ps

# Try to ssh 
ssh -v root@127.0.0.1 -p 2201
