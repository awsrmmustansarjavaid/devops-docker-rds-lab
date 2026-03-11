#!/bin/bash

echo "Updating system"

sudo apt update -y

echo "Installing Docker"

sudo apt install docker.io -y

sudo systemctl start docker
sudo systemctl enable docker

echo "Building Docker Image"

sudo docker build -t devops-lab .

echo "Running Container"

sudo docker run -d -p 80:80 devops-lab

echo "Deployment Complete"