#!/bin/bash

#----------------------------------------------------------------------------------------
#- Name:	    build.sh
#- Author:	    Boldi Olajos
#- Function:    Builds the velocity and papermc images and puts them in a local registry
#- Usage:	    ./build.sh [-h|-p|-r]
#----------------------------------------------------------------------------------------

regport=5000 # local registry's port number
cleanup=1

# processing options
while getopts ":hpr:" opt; do
	case $opt in
		h)
			echo "Builds the velocity and papermc images and puts them in a local registry"
			echo ""
			echo "Syntax: build.sh [-h|-p|-r PORT]"
			echo "options:"
			echo "h    Display this help message"
			echo "p    Preserve built images (do not clean up local images after push)"
			echo "r    Supply a different PORT for the registry to use (default=5000)"
			exit;;
		p)
			cleanup=0;;
		r)
			regport=$OPTARG;;
		*)
			echo "Error: Invalid option, use -h for help" >&2
			exit 1;;
	esac
done

info='\e[36mINFO\e[0m'
warn='\e[33mWARN\e[0m'
error='\e[31mERROR\e[0m'
export DOCKER_CLI_HINTS=false

function build_image {
	imgname=$1
	echo -e "\n\e[32mIMAGE\e[0m: $imgname"
	cd ./$imgname/image

	if docker build -t localhost:$regport/$imgname .; then
		cd - >/dev/null
		return 0
	fi
	
	cd -
	return 1
}

function push_image {
        imgname=$1
	imgfull=localhost:$regport/$imgname
        echo -e "\n\e[32mIMAGE\e[0m: $imgfull"

        if docker push $imgfull; then
		if [[ "$cleanup" == "1" ]]; then
			echo -e "Cleaning up local image..."
			docker image rm $imgfull >/dev/null
		fi
                return 0
        fi

        return 1
}


# ensure that there is a registry container
if [[ -n "$(docker ps -aqf name=registry)" ]]; then
	echo -e "$info: local registry already present"
else
	if docker run -d -p $regport:5000 --name registry registry:2; then
		echo -e "$info: Created local registry running on port $regport"
	else
		echo -e "$error: Failed to create local registry" >&2
		exit 1
	fi
fi

# ensure local registry is running
if [[ -z "$(docker ps -qf name=registry)" ]]; then
	if docker container start registry; then
		echo -e "$info: Started local registry container"
	else
		echo -e "$error: Failed to start local registry" >&2
		exit 1
	fi
fi

# check that we are (likely) in the project root
if [[ !( -d "./papermc" && -d "./velocity" ) ]]; then
	echo -e "$warn: Expected subdirectories not found, please ensure you run this script from the project root!" >&2
	exit 2
fi

# Build images (and tag on the local repository)
echo -e "$info: BUILDING:"
if build_image "papermc" && build_image "velocity"; then
	echo -e "$info: Images built successfully"
else
	echo -e "$error: Image build failed!" >&2
	exit 1
fi

# Push images to local repository
echo -e "$info: PUSHING:"
if push_image "papermc" && push_image "velocity"; then
	echo -e "$info: Images pushed to local repository"
else
	echo -e "$error: Image push failed!" >&2
	exit 1
fi

echo -e "\n\e[32mBUILD COMPLETE\e[0m\n"
