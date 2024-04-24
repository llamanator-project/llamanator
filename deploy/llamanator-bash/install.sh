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
source ../.env
source ../.env && envsubst < "${HAPROXY_PATH}${CONFIG_TEMPLATE}" > "${HAPROXY_PATH}${CONFIG_OUTPUT}"
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

set -a
source .env

# Function to replace placeholders in the template
replace_placeholders() {
    template_file="$1"
    output_file="$2"
    
    # Extract variable names from .env file and replace in template
    while IFS='=' read -r key _; do
        # Replace placeholders with actual values
        sed -i '' -e "s/{{$key}}/${!key}/g" "$output_file"
    done < ../.env
}

# Variables for LINKS files
LINKS_TEMPLATE="./templates/llamanator-links.txt.template"
LINKS_OUTPUT="./llamanator-links.txt"

# Copy template file to output file
cp "$LINKS_TEMPLATE" "$LINKS_OUTPUT"

# Call function to replace placeholders
replace_placeholders "$LINKS_TEMPLATE" "$LINKS_OUTPUT"

set +a
echo -e "\e[32mLlamanator link file created at ${LINKS_OUTPUT}.\e[0m"