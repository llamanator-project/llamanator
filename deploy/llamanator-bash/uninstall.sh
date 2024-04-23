#!/bin/bash

# Function to handle loading errors
handle_error() {
    echo -e "\e[31mError occurred: $1\e[0m"
    exit 1
}

# Load environment variables from .env file
if ! source .env; then
    handle_error "Failed to load environment variables from .env"
fi

echo -e "\e[33mWARNING: This will permanently stop ALL services but LEAVE THE DATA. Type 'YES I UNDERSTAND' to proceed.\e[0m"
read -r confirmation

if [ "$confirmation" != "YES I UNDERSTAND" ]; then
    echo -e "\e[31mUninstall aborted.\e[0m"
    exit 1
fi

# Remove the Llamanator service
# Remove Ollama CPU
if [ "$ENABLE_OLLAMACPU" = "true" ]; then
    echo -e "\e[32mRemoving Ollama CPU...\e[0m"
    docker compose -f ${OLLAMACPU_COMPOSE_FILE} down
else
    echo -e "\e[33mSkipping Ollama CPU...\e[0m"
fi

# Remove Ollama GPU
if [ "$ENABLE_OLLAMAGPU" = "true" ]; then
    echo -e "\e[32mRemoving Ollama GPU...\e[0m"
    docker compose -f ${OLLAMAGPU_COMPOSE_FILE} down
else
    echo -e "\e[33mSkipping Ollama GPU...\e[0m"
fi

# Remove OpenWebUI
if [ "$ENABLE_OPENWEBUI" = "true" ]; then
    echo -e "\e[32mRemoving OpenWebUI...\e[0m"
    docker compose -f ${OPENWEBUI_COMPOSE_FILE} --env-file ${OPENWEBUI_COMPOSE_FILE%/*}/.llamanator-openwebui.env down
    rm -rf ${OPENWEBUI_COMPOSE_FILE%/*}/.llamanator-openwebui.env
else
    echo -e "\e[33mSkipping OpenWebUI...\e[0m"
fi

# Remove Dialoqbase
if [ "$ENABLE_DIALOQBASE" = "true" ]; then
    echo -e "\e[32mRemoving Dialoqbase...\e[0m"
    docker compose -f ${DIALOQBASE_COMPOSE_FILE} --env-file ${DIALOQBASE_COMPOSE_FILE%/*}/.llamanator-dialoqbase.env down
    rm -rf ${DIALOQBASE_COMPOSE_FILE%/*}/.llamanator-dialoqbase.env
else
    echo -e "\e[33mSkipping Dialoqbase...\e[0m"
fi

# Remove HAProxy
docker compose -f ${HAPROXY_COMPOSE_FILE} down

# Remove the private network
if docker network inspect llamanator &> /dev/null; then
    echo -e "\e[32mRemoving private network...\e[0m"
    docker network rm llamanator || handle_error "Removing network" "Failed to remove private network"
else
    echo -e "\e[33mPrivate network does not exist. Skipping removal...\e[0m"
fi