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
models=("llama2" "mistral" "nomic-embed-text" "codellama" "llama3" "phi3")

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
    
    # Clear the output file
    > "$output_file"
    
    # Read template file line by line
    while IFS= read -r line; do
        # Check if line contains a placeholder ({{...}})
        if [[ $line =~ \{\{([^}]+)\}\} ]]; then
            # Extract the placeholder name
            placeholder="${BASH_REMATCH[1]}"
            # Check if the placeholder corresponds to a variable in .env
            if grep -q "^$placeholder=" .env; then
                # Get the value of the variable from .env
                value=$(grep "^$placeholder=" .env | cut -d '=' -f 2-)
                # Replace the placeholder with the value
                line=$(echo "$line" | sed "s|{{$placeholder}}|$value|g")
            fi
        fi
        # Write the line to the output file
        echo "$line" >> "$output_file"
    done < "$template_file"
}

# Copy template file to output file
cp "$LINKS_TEMPLATE" "$LINKS_OUTPUT"

# Call function to replace placeholders
replace_placeholders "$LINKS_TEMPLATE" "$LINKS_OUTPUT"

set +a
echo -e "\e[32mLlamanator link file created at ${LINKS_OUTPUT}.\e[0m"