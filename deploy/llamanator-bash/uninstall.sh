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

echo "$(tput setaf 3)WARNING: This will permanently stop ALL services but LEAVE THE DATA. Type 'YES I UNDERSTAND' to proceed.$(tput sgr0)"
read -r confirmation

if [ "$confirmation" != "YES I UNDERSTAND" ]; then
    echo "$(tput setaf 1)Uninstall aborted.$(tput sgr0)"
    exit 1
fi

# Remove the Llamanator service
# Remove Ollama CPU
if [ "$ENABLE_OLLAMACPU" = "true" ]; then
    echo "$(tput setaf 2)Removing Ollama CPU...$(tput sgr0)"
    docker compose -f ${OLLAMACPU_COMPOSE_FILE} down
else
    echo "$(tput setaf 3)Skipping Ollama CPU...$(tput sgr0)"
fi

# Remove Ollama GPU
if [ "$ENABLE_OLLAMAGPU" = "true" ]; then
    echo "$(tput setaf 2)Removing Ollama GPU...$(tput sgr0)"
    docker compose -f ${OLLAMAGPU_COMPOSE_FILE} down
else
    echo "$(tput setaf 3)Skipping Ollama GPU...$(tput sgr0)"
fi

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
docker compose -f ${HAPROXY_COMPOSE_FILE} down

# Remove the private network
if docker network inspect llamanator &> /dev/null; then
    echo "$(tput setaf 2)Removing private network...$(tput sgr0)"
    docker network rm llamanator || handle_error "Removing network" "Failed to remove private network"
else
    echo "$(tput setaf 3)Private network does not exist. Skipping removal...$(tput sgr0)"
fi
