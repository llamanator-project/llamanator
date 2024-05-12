#!/bin/bash

# Function to handle loading errors
handle_error() {
    echo "$(tput setaf 1)Error occurred: $1$(tput sgr0)"
    exit 1
}

# Load environment variables from .env file
if ! source .env; then
    handle_error "Failed to load environment variables from .env"
fi

# Check if the --remove-all-data flag is provided
if [ "$1" = "--remove-all-data" ]; then
    echo "$(tput setaf 3)WARNING: This will permanently remove ALL data and services. Type 'YES I UNDERSTAND' to proceed.$(tput sgr0)"
    read -r confirmation
    if [ "$confirmation" != "YES I UNDERSTAND" ]; then
        echo "$(tput setaf 1)Uninstall aborted.$(tput sgr0)"
        exit 1
    fi

    # Remove the Llamanator service with volumes
    echo "$(tput setaf 2)Removing Ollama...$(tput sgr0)"
    docker compose -f ${OLLAMA_COMPOSE_FILE} down -v

    # Remove OpenWebUI
    if [ "$ENABLE_OPENWEBUI" = "true" ]; then
        echo "$(tput setaf 2)Removing OpenWebUI...$(tput sgr0)"
        docker compose -f ${OPENWEBUI_COMPOSE_FILE} --env-file ${OPENWEBUI_COMPOSE_FILE%/*}/.llamanator-openwebui.env down -v
        rm -rf ${OPENWEBUI_COMPOSE_FILE%/*}/.llamanator-openwebui.env
    else
        echo "$(tput setaf 3)Skipping OpenWebUI...$(tput sgr0)"
    fi

    # Remove Dialoqbase
    if [ "$ENABLE_DIALOQBASE" = "true" ]; then
        echo "$(tput setaf 2)Removing Dialoqbase...$(tput sgr0)"
        docker compose -f ${DIALOQBASE_COMPOSE_FILE} --env-file ${DIALOQBASE_COMPOSE_FILE%/*}/.llamanator-dialoqbase.env down -v
        rm -rf ${DIALOQBASE_COMPOSE_FILE%/*}/.llamanator-dialoqbase.env
    else
        echo "$(tput setaf 3)Skipping Dialoqbase...$(tput sgr0)"
    fi

    # Remove Haproxy
    docker compose -f ${HAPROXY_COMPOSE_FILE} down -v
    sudo rm -rf ${HAPROXY_PATH}/certs
    rm -f ${HAPROXY_PATH}/haproxy.cfg

    # Remove Links file
    echo -e "$(tput setaf 2)Removing links file...$(tput setaf 0)"
    rm -f ${LINKS_OUTPUT}
else
    # Remove the Llamanator service without volumes
    echo "$(tput setaf 2)Removing Ollama ...$(tput sgr0)"
    docker compose -f ${OLLAMA_COMPOSE_FILE} down

    # Remove OpenWebUI
    if [ "$ENABLE_OPENWEBUI" = "true" ]; then
        echo "$(tput setaf 2)Removing OpenWebUI...$(tput sgr0)"
        docker compose -f ${OPENWEBUI_COMPOSE_FILE} --env-file ${OPENWEBUI_COMPOSE_FILE%/*}/.llamanator-openwebui.env down
    else
        echo "$(tput setaf 3)Skipping OpenWebUI...$(tput sgr0)"
    fi

    # Remove Dialoqbase
    if [ "$ENABLE_DIALOQBASE" = "true" ]; then
        echo "$(tput setaf 2)Removing Dialoqbase...$(tput sgr0)"
        docker compose -f ${DIALOQBASE_COMPOSE_FILE} --env-file ${DIALOQBASE_COMPOSE_FILE%/*}/.llamanator-dialoqbase.env down
    else
        echo "$(tput setaf 3)Skipping Dialoqbase...$(tput sgr0)"
    fi

    # Remove HAProxy
    docker compose -f ${HAPROXY_PATH}/docker-compose.yml down
fi

# Remove the private network
if docker network inspect llamanator &> /dev/null; then
    echo "$(tput setaf 2)Removing private network...$(tput sgr0)"
    docker network rm llamanator || handle_error "Removing network" "Failed to remove private network"
else
    echo "$(tput setaf 3)Private network does not exist. Skipping removal...$(tput sgr0)"
fi
