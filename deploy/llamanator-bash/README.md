# Llamanator Bash

Llamanator Bash is a collection of scripts to install and uninstall the Llamanator project on a Linux machine. Llamanator Bash is a proof of concept and is not recommended for production use.

We will be releasing other versions of Llamanator that will be more secure and easier to use.

---
## Table of Contents
- [Llamanator Bash](#llamanator-bash)
  - [Table of Contents](#table-of-contents)
  - [Security](#security)
  - [Tools and Models Included](#tools-and-models-included)
  - [Prerequisites](#prerequisites)
    - [Linux](#linux)
    - [MacOS](#macos)
  - [Install Docker and Docker Compose](#install-docker-and-docker-compose)
    - [Linux](#linux-1)
    - [MacOS](#macos-1)
  - [Using Your Own TLS Certificates](#using-your-own-tls-certificates)
    - [Option 1 - Automatic Self Signed](#option-1---automatic-self-signed)
    - [Option 2 - User Provided](#option-2---user-provided)
  - [Install Llamanator Bash on Linux](#install-llamanator-bash-on-linux)
  - [Install Llamanator Bash on MacOS](#install-llamanator-bash-on-macos)
  - [.env File Options](#env-file-options)
  - [Uninstall Llamanator Bash](#uninstall-llamanator-bash)
  - [Restarting Llamanator Bash](#restarting-llamanator-bash)
  - [Note about Ollama](#note-about-ollama)
    - [Linux](#linux-2)
    - [MacOS](#macos-2)
  - [Cleaning Up Docker](#cleaning-up-docker)
  - [Primary Project Sponsors:](#primary-project-sponsors)
    - [AlphaBravo](#alphabravo)

---

## Security

This script exposes many ports and services on your system. It is recommended that you put a firewall in front of your server to only allow your IP address to access the server or run this on a private network.

---

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

---

## Prerequisites

### Linux

- Ubuntu 22.04
- Docker
- Docker Compose
- Nvidia GPU (if you want to run the Ollama GPU service)
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

---

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

---

## Using Your Own TLS Certificates

If you intend on installing with a domain name and using the proxy, there are 2 options.

### Option 1 - Automatic Self Signed

Let the script generate a self-signed certificate for you. This is the easiest option and is recommended for most users.

### Option 2 - User Provided

Generate your own valid TLS certificates and use them with the proxy.

You will need to create a file called `cert-bundle.pem` with the `private.key` at the top followed by the `fullchain.pem` file in a single file. Make sure all headers and footers are included like `-----BEGIN-----` and `-----END-----`.

Once you have created the `cert-bundle.pem` file, you need to place it in the `./deploy/llamanator-bash/services/llamanator/haproxy/user-provided-certs` directory.

Once that is done, run the install script with the `--install-proxy` option as shown below.

---

## Install Llamanator Bash on Linux

1. Clone this repo (if you haven't already): `git clone https://github.com/llamanator-project/llamanator.git`
2. Change directory to the Llamanator Bash directory: `cd llamanator/deploy/llamanator-bash`
3. Copy the `.env.example` file to `.env`: `cp .env.example .env`
4. Edit the `.env` file to enable the services you want to run. Please review the .env instructions below for the required options.
5. Run the install script:
    - To install with the Proxy on 80/443 run: `sudo ./install.sh --install-proxy`
    - To install without the Proxy run: `sudo ./install.sh`
6. Once complete, open the `./llamanator-links.txt` file to access your services

---

## Install Llamanator Bash on MacOS

1. Install Ollama on your Mac: https://ollama.com
2. Set Ollama to be exposed on your machine by running `launchctl setenv OLLAMA_HOST "0.0.0.0"` and then restarting Ollama
3. Clone this repo (if you haven't already): `git clone https://github.com/llamanator-project/llamanator.git`
4. Change directory to the Llamanator Bash directory: `cd llamanator/deploy/llamanator-bash`
5. Copy the `.env.example` file to `.env`: `cp .env.example .env`
6. Edit the `.env` file to enable the services you want to run. Please review the .env instructions below for the required options.
7. Run the install script:
    - To install with the Proxy on 80/443 run: `sudo ./install.sh --install-proxy`
    - To install without the Proxy run: `sudo ./install.sh`
8. Once complete, open the `./llamanator-links.txt` file to access your services

*NOTE ABOUT MACOS*: In some services, the `127.0.0.1` and `localhost` may not work. You may need to use the IP address of your machine to access the services.

---


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

---

## Uninstall Llamanator Bash

There are 2 options to remove the Llamanator project from your machine:

1. Just stop the services and keep the data: `sudo ./uninstall.sh`
2. Stop the services and remove all data: `sudo ./uninstall.sh --remove-all-data`

---

## Restarting Llamanator Bash

Regardless of the uninstall option you choose, you can restart the Llamanator project by running the `./install.sh` script again. If the volumes are still present, the data will be re-attached to the services. If you removed the data, the services will start fresh.

---

## Note about Ollama

### Linux

The Ollama data is stored locally on the disk so you can prevent having to download the LLMs again. The data is stored on the host filesystem in the `ollama_data` directory. If you want to remove the Ollama data, you can delete the `./services/ollama/ollama_data` directory.

### MacOS

The Ollama data is stored `~/.ollama/models` directory. If you want to remove all Ollama data, you can delete the `~/.ollama/models` directory.

If you only want to remove specific LLMs, you can run `ollama rm <model_name>` to remove the LLM from the Ollama service.

---

## Cleaning Up Docker

If you want to clean up Docker, you can run the `docker system prune -a` command. This will remove all stopped containers, all networks not used by at least one container, all dangling images, and all build cache.

---

## Primary Project Sponsors:

### AlphaBravo
<img src="../../assets/images/alphabravo-logo-1.png" alt="drawing" width="400"/>

- **Website:** [http://alphabravo.io](https://alphabravo.io/)
- **About:** AlphaBravo is a SDVOSB (Service Disabled Veteran Owned Small Business) that provides a wide range of DevSecOps services, software development and training to the US Government and commercial clients.