#!/bin/bash

#---------------------------------------------------------
#- Name:	    deploy-minikube.sh
#- Author:	    Boldi Olajos
#- Function:    Local kubernetes deployment with minikube
#- Usage:	    ./deploy-minikube.sh
#---------------------------------------------------------

wanted_memory=7168 # maximum memory (in MB) for minikube
wanted_cpus=4 # cpu count given to minikube

info='\e[36mINFO\e[0m'
warn='\e[33mWARN\e[0m'
error='\e[31mERROR\e[0m'

# check we have all dependencies (minikube, docker, kubectl)
command -v minikube >/dev/null
if [[ ! $? ]]; then
    echo -e "$error: missing dependency: minikube" >&2
    exit 1
fi
command -v docker >/dev/null
if [[ ! $? ]]; then
    echo -e "$error: missing dependency: docker" >&2
    exit 1
fi
command -v kubectl >/dev/null
if [[ ! $? ]]; then
    echo -e "$error: missing dependency: kubectl" >&2
    exit 1
fi

# check that we are (likely) in the project root
if [[ !( -d "./papermc" && -d "./velocity" ) ]]; then
    echo -e "$warn: Expected subdirectories not found, please ensure you run this script from the project root!" >&2
    exit 2
fi

# run build script
./build.sh

# ensure minikube has enough maximum memory and cpus configured
change_memory=0
change_cpus=0

configured_memory=$(minikube config get memory 2>/dev/null)
if [[ $configured_memory -ge $wanted_memory ]]; then
    echo -e "$info: minikube maximum memory is currently configured as $configured_memory MB (wanted: $wanted_memory)"
else
    echo -e "$warn: minikube has insufficient maximum memory configured ($configured_memory), this will be changed to $wanted_memory MB" >&2
    change_memory=1
fi
configured_cpus=$(minikube config get cpus 2>/dev/null)
if [[ $configured_cpus -ge $wanted_cpus ]]; then
    echo -e "$info: minikube maximum CPUs is currently configured as $configured_cpus (wanted: $wanted_cpus)"
else
    echo -e "$warn: minikube has insufficient maximum CPUs configured ($configured_cpus), this will be changed to $wanted_cpus" >&2
    change_cpus=1
fi

# ask for confirmation before reconfiguring (since it requires the minikube container to be deleted)
if [[ "$change_memory" == "1" || "$change_cpus" == "1" ]]; then
    echo -en "$warn: This change will \e[31mdelete the current minikube\e[0m cluster, do you wish to continue? " 
    read -p "[y/N]: " reply
    if [[ "$reply" == "y" ]]; then
        echo -e "$info: Deleting cluster..."
        minikube delete
        echo -e "\n$info: Updating config and restarting..."
        if [[ "$change_memory" == "1" ]]; then
            minikube config set memory $wanted_memory >/dev/null
        fi
        if [[ "$change_cpus" == "1" ]]; then
            minikube config set cpus $wanted_cpus >/dev/null
        fi
        minikube start
    else
        exit 2
    fi
fi

echo -e "\n$info: Uploading images to minikube..."

if minikube image load localhost:5000/papermc && minikube image load localhost:5000/velocity; then
    echo -e "$info: upload success"
else
    echo -e "$error: Failed to upload images to minikube" >&2
    exit 1
fi

echo -e "$info: Uploading config volumes to kubernetes host (minikube container)..."

if docker container cp ./papermc/configs minikube:/configs && docker container cp ./velocity/configs minikube:/configs; then
    echo -e "$info: upload success"
else
    echo -e "$error: Failed to upload configs to minikube" >&2
    exit 1
fi

echo -e "\n$info: Redeploying cluster..."
kubectl delete -f kubernetes.yml
kubectl create -f kubernetes.yml

if [[ $? ]]; then
    echo -e "\n\e[32mDEPLOY COMPLETE\e[0m\n"

    echo -e "Run \e[32mminikube tunnel\e[0m to publish the proxy service on port 25565, (minecraft will then be able to connect to localhost)."
    exit 0
else
    echo -e "\n\e[31mDEPLOY FAILED\e[0m\n" >&2
    exit 1
fi

