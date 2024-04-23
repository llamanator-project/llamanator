#!/bin/bash

# Load environment variables from .env file
source .env

# Function to skip a service
skip_service() {
    echo -e "\e[33mSkipping service $1...\e[0m"
}

# Define path to the user-provided cert-bundle.pem
CERT_BUNDLE_PATH="${HAPROXY_PATH}/user-provided-certs/cert-bundle.pem"

# Check if cert-bundle.pem does not exist
if [ ! -f "$CERT_BUNDLE_PATH" ]; then
    echo -e "\e[32mSetting up SSL certificates...\e[0m"
    
    # Ensure the target directory exists
    mkdir -p "${HAPROXY_PATH}/certs"
    
    # Run Docker container to generate SSL certificates
    docker run --rm -v "${HAPROXY_PATH}/certs:/certs" -e SSL_SUBJECT="${DOMAIN_NAME}" -e SSL_IP="${SERVER_IP}" paulczar/omgwtfssl > /dev/null 2>&1
    
    # Concatenate key and cert into a single bundle
    sudo cat "${HAPROXY_PATH}/certs/key.pem" "${HAPROXY_PATH}/certs/cert.pem" > "${HAPROXY_PATH}/certs/cert-bundle.pem"
else
    echo -e "\e[33mUser-provided SSL certificate bundle already exists. Skipping setup...\e[0m"
fi

# Copy user provided certs
if [ -f "$CERT_BUNDLE_PATH" ]; then
    echo -e "\e[32mCopying user-provided SSL certificates...\e[0m"
    mkdir -p "${HAPROXY_PATH}/certs"
    cp "$CERT_BUNDLE_PATH" "${HAPROXY_PATH}/certs/cert-bundle.pem"
else
    echo -e "\e[33mUser-provided SSL certificate bundle not found. Skipping copy...\e[0m"
fi

# Substitute environment variables into the HAProxy configuration
set -a
source .env
source .env && envsubst < "${HAPROXY_PATH}${CONFIG_TEMPLATE}" > "${HAPROXY_PATH}${CONFIG_OUTPUT}"
set +a
echo -e "\e[32mHAProxy configuration file created.\e[0m"

# Run HAProxy
echo -e "\e[32mDeploying HAProxy...\e[0m"
docker compose -f ${HAPROXY_PATH}/docker-compose.yml up -d

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

# Ollama CPU download models
if [ "$ENABLE_OLLAMACPU" = "true" ] && [ "$ENABLE_OLLAMA_BASE_MODELS" = "true" ]; then
    echo -e "\e[32mDownloading Ollama models...\e[0m"
    echo -e "\e[32mDownloading llama2...\e[0m"
    docker exec -it ollama ollama pull llama2
    echo -e "\e[32mDownloading mistral...\e[0m"
    docker exec -it ollama ollama pull mistral
    echo -e "\e[32mDownloading nomic-embed-text...\e[0m"
    docker exec -it ollama ollama pull nomic-embed-text
    echo -e "\e[32mDownloading codellama...\e[0m"
    docker exec -it ollama ollama pull codellama
    echo -e "\e[32mDownloading llama3...\e[0m"
    docker exec -it ollama ollama pull llama3
else
    skip_service "Ollama CPU base model download..."
fi

# Ollama GPU download models
if [ "$ENABLE_OLLAMAGPU" = "true" ] && [ "$ENABLE_OLLAMA_BASE_MODELS" = "true" ]; then
    echo -e "\e[32mDownloading Ollama models...\e[0m"
    echo -e "\e[32mDownloading llama2...\e[0m"
    docker exec -it ollama ollama pull llama2
    echo -e "\e[32mDownloading mistral...\e[0m"
    docker exec -it ollama ollama pull mistral
    echo -e "\e[32mDownloading nomic-embed-text...\e[0m"
    docker exec -it ollama ollama pull nomic-embed-text
    echo -e "\e[32mDownloading codellama...\e[0m"
    docker exec -it ollama ollama pull codellama
    echo -e "\e[32mDownloading llama3...\e[0m"
    docker exec -it ollama ollama pull llama3
else
    skip_service "Ollama GPU base model download..."
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
source .env
envsubst < "${LINKS_TEMPLATE}" > "${LINKS_OUTPUT}"
set +a
echo -e "\e[32mLlamanator link file created at ${LINKS_OUTPUT}.\e[0m"