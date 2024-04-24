#!/bin/bash

# Load environment variables from .env file
source .env

# Function to skip a service
skip_service() {
    echo "$(tput setaf 3)Skipping service $1...$(tput sgr0)"
}

# Create private network
if ! docker network inspect llamanator &> /dev/null; then
    echo "$(tput setaf 2)Creating private network...$(tput sgr0)"
    docker network create llamanator || handle_error "Creating network" "Failed to create private network"
else
    echo "$(tput setaf 3)Private network already exists. Skipping creation...$(tput sgr0)"
fi

## Ollama CPU
if [ "$ENABLE_OLLAMACPU" = "true" ]; then
    echo "$(tput setaf 2)Deploying Ollama CPU...$(tput sgr0)"
    docker compose -f ${OLLAMACPU_COMPOSE_FILE} up -d
else
    skip_service "Ollama CPU"
fi

# Ollama GPU
if [ "$ENABLE_OLLAMAGPU" = "true" ]; then
    echo "$(tput setaf 2)Deploying Ollama GPU...$(tput sgr0)"
    docker compose -f ${OLLAMAGPU_COMPOSE_FILE} up -d
else
    skip_service "Ollama GPU"
fi

# Define a common list of models to download
models=("llama2" "mistral" "nomic-embed-text" "codellama" "llama3" "phi3")

# Function to download models
download_models() {
    for model in "${models[@]}"; do
        echo "$(tput setaf 2)Downloading $model...$(tput sgr0)"
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
        echo "$(tput setaf 2)Downloading Ollama models...$(tput sgr0)"
        
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
    echo "$(tput setaf 2)Deploying OpenWebUI...$(tput sgr0)"
    cat ${OPENWEBUI_COMPOSE_FILE%/*}/.env .env > ${OPENWEBUI_COMPOSE_FILE%/*}/.llamanator-openwebui.env
    docker compose -f ${OPENWEBUI_COMPOSE_FILE} --env-file ${OPENWEBUI_COMPOSE_FILE%/*}/.llamanator-openwebui.env up -d
else
    skip_service "OpenWebUI"
fi

# Dialoqbase
if [ "$ENABLE_DIALOQBASE" = "true" ]; then
    echo "$(tput setaf 2)Deploying Dialoqbase...$(tput sgr0)"
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
        while [[ $line =~ \{\{([^}]+)\}\} ]]; do
            # Extract the placeholder name
            placeholder="${BASH_REMATCH[1]}"
            # Check if the placeholder corresponds to a variable in .env
            if grep -q "^$placeholder=" .env; then
                # Get the value of the variable from .env
                value=$(grep "^$placeholder=" .env | cut -d '=' -f 2-)
                # Replace the placeholder with the value
                line=$(echo "$line" | sed "s|{{$placeholder}}|$value|g")
            else
                # If placeholder not found, exit the loop
                break
            fi
        done
        # Write the line to the output file
        echo "$line" >> "$output_file"
    done < "$template_file"
}

# Copy template file to output file
cp "$LINKS_TEMPLATE" "$LINKS_OUTPUT"

# Call function to replace placeholders
replace_placeholders "$LINKS_TEMPLATE" "$LINKS_OUTPUT"

set +a
echo "$(tput setaf 2)Llamanator link file created at ${LINKS_OUTPUT}.$(tput sgr0)"
