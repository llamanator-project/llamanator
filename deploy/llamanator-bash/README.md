# Llamanator Bash

Llamanator Bash is a collection of scripts to install and uninstall the Llamanator project on a Linux machine. Llamanator Bash is a proof of concept and is not recommended for production use.

We will be releasing other versions of Llamanator that will be more secure and easier to use.

## Security

This script exposes many ports and services on your system. It is recommended that you put a firewall in front of your server to only allow your IP address to access the server or run this on a private network.

## Prerequisites

- Ubuntu 22.04
- Docker
- Docker Compose
- Recommended 16vCPU and 32GB RAM (depending on services you want to run)
- At least 100GB of free disk space
- A user with sudo privileges (preferably passwordless sudo)

## Install Llamanator Bash

1. Clone this repo (if you haven't already): `git clone https://github.com/llamanator-project/llamanator.git`
2. Change directory to the Llamanator Bash directory: `cd llamanator/deploy/llamanator-bash`
3. Copy the `.env.example` file to `.env`: `cp .env.example .env`
4. Edit the `.env` file to enable the services you want to run
5. Run the install script: `sudo ./install.sh`
6. Once complete, open the `./llamanator-links.txt` file to access your services

## Uninstall Llamanator Bash

There are 2 options to remove the Llamanator project from your machine:

**Option 1**: Run the uninstall script: `sudo ./uninstall.sh`. This will remove all Llamanator services but leave the Docker volumes. This is useful if you want to just run the `./install.sh` script again to bring all services back up and still have access to your previous data.

**Option 2**: Run the uninstall script with the `sudo  ./uninstall_remove_data.sh`. This will remove all Llamanator services and the Docker volumes. This is useful if you want to completely remove the Llamanator project from your machine.

## Note about Ollama

The Ollama data is stored locally on the disk so you can prevent having to download the LLMs again. The data is stored on the host filesystem in the `ollama_data` directory. If you want to remove the Ollama data, you can delete the `./services/ollama/ollama_data` directory.

## Cleaning Up Docker

If you want to clean up Docker, you can run the `docker system prune -a` command. This will remove all stopped containers, all networks not used by at least one container, all dangling images, and all build cache.

---

## Primary Project Sponsors:

### HighSide.ai
<img src="../../assets/images/highside.ai-logo1-wide.png" alt="drawing" width="400"/>

- **Website:** [https://highside.ai](https://highside.ai/)
- **About:** HighSide.ai is a company that provides a wide range of scalable AI services to the US Government and DoD. From privately AI applications to secure LLM inferencing and ML training environments, HighSide.ai is a leader in secure AI.

---

### AlphaBravo
<img src="../../assets/images/alphabravo-logo-1.png" alt="drawing" width="400"/>

- **Website:** [http://alphabravo.io](https://alphabravo.io/)
- **About:** AlphaBravo is a SDVOSB (Service Disabled Veteran Owned Small Business) that provides a wide range of DevSecOps services, software development and training to the US Government and commercial clients.