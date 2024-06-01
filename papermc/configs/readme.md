# Example Minecraft Server Configurations

## What is this folder?
This folder contains example configurations for minecraft servers with different game modes,
such as a _survival_ and a _lobby/creative_ server. 

[See the PaperMC documentation](https://docs.papermc.io/paper/reference/configuration) to learn more about the possible configuration files
and options.

## How does it work?
These folders can be mounted (via `-v`) during `docker run` to `/serverconfig`, which will copy all files 
to the actual working directory `/paper`, and overwrite any files already present there _(from the base-config the image was built with)_,
this allows you to easily reconfigure the containers in different ways without having to build different images.

