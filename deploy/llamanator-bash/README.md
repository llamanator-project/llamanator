# Llamanator Bash

Llamanator Bash is a collection of scripts to install and uninstall the Llamanator project on a Linux machine. Llamanator Bash is a proof of concept and is not recommended for production use.

We will be releasing other versions of Llamanator that will be more secure and easier to use.

## Security

This script exposes many ports and services on your system. It is recommended that you put a firewall in front of your server to only allow your IP address to access the server or run this on a private network.

## Tools and Models Included

**Tools:**
- [Ollama](https://ollama.com)
- [OpenWebUI](https://github.com/open-webui/open-webui)
- [Dialoqbase](https://github.com/n4ze3m/dialoqbase)
- HAProxy running on 80/443 to route traffic to the services

**Models (LLMs):**
- Llama2
- Llama3
- Mistral
- Nomic Embed
- Codellama
- Phi3

## Prerequisites

### Linux

- Ubuntu 22.04
- Docker
- Docker Compose
- NVidia GPU (if you want to run the Ollama GPU service)
- Recommended 16vCPU and 32GB RAM (depending on services you want to run)
- At least 100GB of free disk space
- A user with sudo privileges (preferably passwordless sudo)
- Port 80 and 443 open on your machine (if you want to use the proxy)

### MacOS

- MacOS >12.0.1
- Docker Desktop for Mac
- M1 or better processor
- Mac Integrated GPU
- At least 32GB of RAM
- At least 100GB of free disk space
- Port 80 and 443 open on your machine (if you want to use the proxy)

## Install Docker and Docker Compose

### Linux
If you system already has Docker and Docker Compose installed, you can skip this step.

Make sure that you have the Nvidia container toolkit installed on your system if you choose the GPU install. You can follow the instructions here: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

**Option 1**

If you want to install Docker and Docker Compose with out provided script, you can follow the instructions below:

1. Run the following command to install Docker: `./install_docker_ubuntu.sh`
2. If you are not running as root, run the following command to add your user to the Docker group: `sudo usermod -aG docker $USER`
3. Logout and log back into your terminal session
4. Verify that Docker is installed by running: `docker --version`

**Option 2**

Follow the instructions from the official Docker website to install Docker and Docker Compose: https://docs.docker.com/engine/install/ubuntu/

And then install the Nvidia container toolkit if you are have an Nvidia GPU: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html

### MacOS

1. Install Docker Desktop for Mac: https://docs.docker.com/desktop/install/mac-install/

## Install Llamanator Bash on Linux

1. Clone this repo (if you haven't already): `git clone https://github.com/llamanator-project/llamanator.git`
2. Change directory to the Llamanator Bash directory: `cd llamanator/deploy/llamanator-bash`
3. Copy the `.env.example` file to `.env`: `cp .env.example .env`
4. Edit the `.env` file to enable the services you want to run. Please review the .env instructions below for the required options.
5. Run the install script:
    - To install with the Proxy on 80/443 run: `sudo ./install.sh`
    - To install without the Proxy run: `sudo ./install_no_proxy.sh`
6. Once complete, open the `./llamanator-links.txt` file to access your services


## Install Llamanator Bash on MacOS with Proxy

1. Install Ollama on your Mac: https://ollama.com
2. Set Ollama to be exposed on your machine by running `launchctl setenv OLLAMA_HOST "0.0.0.0"` and then restarting Ollama
3. Clone this repo (if you haven't already): `git clone https://github.com/llamanator-project/llamanator.git`
4. Change directory to the Llamanator Bash directory: `cd llamanator/deploy/llamanator-bash`
5. Copy the `.env.example` file to `.env`: `cp .env.example .env`
6. Edit the `.env` file to enable the services you want to run. Please review the .env instructions below for the required options.
7. Run the install script:
    - To install with the Proxy on 80/443 run: `sudo ./install.sh`
    - To install without the Proxy run: `sudo ./install_no_prox.sh`
8. Once complete, open the `./llamanator-links.txt` file to access your services


## .env File Options

Below are the only values you should need to change in the `.env` file:

- `ENABLE_OLLAMACPU`: Set to `true` to enable the Ollama service on a linux machine with only a CPU and no GPU (set to `false` if running on MacOS)
- `ENABLE_OLLAMAGPU`: Set to `true` to enable the Ollama service on a linux machine with a GPU (set to `false` if running on MacOS)
- `ENABLE_OLLAMA_BASE_MODELS`: Set to `true` to enable the Ollama base model downloads. This will download the base models for the Ollama service.
- `ENABLE_OPENWEBUI`: Set to `true` to enable the OpenWebUI service
- `ENABLE_DIALOQBASE`: Set to `true` to enable the Dialoqbase Retrieval Augmented Generation (RAG) service
- `SERVER_IP`: Set this to `127.0.0.1` if you are running on a local machine. If you are running on a server and want other machines to be able to access the services, set this to the IP address of the server.
- `DOMAIN_NAME`: Set this to the domain name of your server if you have one (must use the install with Proxy). You will want to point the following entries to the IP address of your server in your DNS settings.
  - openwebui.yourdomain.com
  - dialoqbase.yourdomain.com
- `OLLAMA_ENDPOINT`: If you want to inference against an Ollama service running on a different machine, set this to the IP address or domain name of the machine running the Ollama service. If you are running the Ollama service on the same machine, leave this as `127.0.0.1`. Make sure that your Ollama service is exposed on the network and the machine you are running the Llamanator Bash script on can access the Ollama service.

## Uninstall Llamanator Bash

There are 2 options to remove the Llamanator project from your machine:

**Option 1**: Run the uninstall script: `sudo ./uninstall.sh`. This will remove all Llamanator services but leave the Docker volumes. This is useful if you want to just run the `./install.sh` script again to bring all services back up and still have access to your previous data.

**Option 2**: Run the uninstall script with the `sudo  ./uninstall_remove_data.sh`. This will remove ALL Llamanator services and the Docker volumes (including ALL data). This is useful if you want to completely remove the Llamanator project from your machine.

## Note about Ollama

### Linux

The Ollama data is stored locally on the disk so you can prevent having to download the LLMs again. The data is stored on the host filesystem in the `ollama_data` directory. If you want to remove the Ollama data, you can delete the `./services/ollama/ollama_data` directory.

### MacOS

The Ollama data is stored `~/.ollama/models` directory. If you want to remove all Ollama data, you can delete the `~/.ollama/models` directory.

If you only want to remove specific LLMs, you can run `ollama rm <model_name>` to remove the LLM from the Ollama service.

## Cleaning Up Docker

If you want to clean up Docker, you can run the `docker system prune -a` command. This will remove all stopped containers, all networks not used by at least one container, all dangling images, and all build cache.

---

## Primary Project Sponsors:

### HighSide.ai
<img src="../../assets/images/highsideai-logo1-wide.png" alt="drawing" width="400"/>

- **Website:** [https://highside.ai](https://highside.ai/)
- **About:** HighSide.ai is a company that provides a wide range of scalable AI services to the US Government and DoD. From privately AI applications to secure LLM inferencing and ML training environments, HighSide.ai is a leader in secure AI.

---

### AlphaBravo
<img src="../../assets/images/alphabravo-logo-1.png" alt="drawing" width="400"/>

- **Website:** [http://alphabravo.io](https://alphabravo.io/)
- **About:** AlphaBravo is a SDVOSB (Service Disabled Veteran Owned Small Business) that provides a wide range of DevSecOps services, software development and training to the US Government and commercial clients.