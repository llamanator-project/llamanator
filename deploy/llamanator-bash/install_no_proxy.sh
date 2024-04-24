#!/bin/bash

# Load environment variables from .env file
source .env

# Function to skip a service
skip_service() {
    echo -e "\e[33mSkipping service $1...\e[0m"
}

# Create private network
if ! docker network inspect llamanator &> /dev/null; then
    echo -e "\e[32mCreating private network...\e[0m"
    docker network create llamanator || handle_error "Creating network" "Failed to create private network"
else
    echo -e "\e[33mPrivate network already exists. Skipping creation...\e[0m"
fi

## Ollama CPU
if [ "$ENABLE_OLLAMACPU" = "true" ]; then
    echo -e "\e[32mDeploying Ollama CPU...\e[0m"
    docker compose -f ${OLLAMACPU_COMPOSE_FILE} up -d
else
    skip_service "Ollama CPU"
fi

# Ollama GPU
if [ "$ENABLE_OLLAMAGPU" = "true" ]; then
    echo -e "\e[32mDeploying Ollama GPU...\e[0m"
    docker compose -f ${OLLAMAGPU_COMPOSE_FILE} up -d
else
    skip_service "Ollama GPU"
fi

# Define a common list of models to download
models=("llama2" "mistral" "nomic-embed-text" "codellama" "llama3")

# Function to download models
download_models() {
    for model in "${models[@]}"; do
        echo -e "\e[32mDownloading $model...\e[0m"
        # Check if the system is macOS
        if [ "$(uname)" == "Darwin" ]; then
            ollama pull "$model"
        else
            docker exec -it ollama ollama pull "$model"
        fi
    done
}

# Check if the system is macOS
if [ "$(uname)" == "Darwin" ]; then
    download_models
else
    # Check if base models are enabled
    if [ "$ENABLE_OLLAMA_BASE_MODELS" = "true" ]; then
        echo -e "\e[32mDownloading Ollama models...\e[0m"
        
        # Check if CPU models are enabled
        if [ "$ENABLE_OLLAMACPU" = "true" ]; then
            download_models
        else
            skip_service "Ollama CPU base model download..."
        fi
        
        # Check if GPU models are enabled
        if [ "$ENABLE_OLLAMAGPU" = "true" ]; then
            download_models
        else
            skip_service "Ollama GPU base model download..."
        fi
    fi
fi

# OpenWebUI
if [ "$ENABLE_OPENWEBUI" = "true" ]; then
    echo -e "\e[32mDeploying OpenWebUI...\e[0m"
    cat ${OPENWEBUI_COMPOSE_FILE%/*}/.env .env > ${OPENWEBUI_COMPOSE_FILE%/*}/.llamanator-openwebui.env
    docker compose -f ${OPENWEBUI_COMPOSE_FILE} --env-file ${OPENWEBUI_COMPOSE_FILE%/*}/.llamanator-openwebui.env up -d
else
    skip_service "OpenWebUI"
fi

# Dialoqbase
if [ "$ENABLE_DIALOQBASE" = "true" ]; then
    echo -e "\e[32mDeploying Dialoqbase...\e[0m"
    cat ${DIALOQBASE_COMPOSE_FILE%/*}/.env .env > ${DIALOQBASE_COMPOSE_FILE%/*}/.llamanator-dialoqbase.env
    docker compose -f ${DIALOQBASE_COMPOSE_FILE} --env-file ${DIALOQBASE_COMPOSE_FILE%/*}/.llamanator-dialoqbase.env up -d
else
    skip_service "Dialoqbase"
fi

# Create Links TXT file
set -a
source ../.env
envsubst < "${LINKS_TEMPLATE}" > "${LINKS_OUTPUT}"
set +a
echo -e "\e[32mLlamanator link file created at ${LINKS_OUTPUT}.\e[0m"