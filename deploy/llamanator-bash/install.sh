#!/bin/bash

# Load environment variables from .env file
source .env

# Function to skip a service
skip_service() {
    echo "$(tput setaf 3)Skipping service $1...$(tput sgr0)"
}

# Define path to the user-provided cert-bundle.pem
CERT_BUNDLE_PATH="${HAPROXY_PATH}/user-provided-certs/cert-bundle.pem"

# Function to substitute variables in the template file
# Function to substitute variables in the template file
substitute_variables() {
    local template_file="$1"
    local output_file="$2"
    : > "$output_file" # Clear the output file before writing

    # Read the template file line by line
    while IFS= read -r line; do
        # Check if line contains a placeholder (variable in the format "{{VAR_NAME}}")
        while [[ $line =~ \{\{([^}]+)\}\} ]]; do
            # Extract the variable name from the placeholder
            variable="${BASH_REMATCH[1]}"
            # Get the value of the variable from the environment
            value="${!variable}"
            # Replace the placeholder with the value
            line="${line//\{\{$variable\}\}/$value}"
        done
        # Write the line to the output file
        echo "$line" >> "$output_file"
    done < "$template_file"
}


# Check if cert-bundle.pem does not exist
if [ ! -f "$CERT_BUNDLE_PATH" ]; then
    echo "$(tput setaf 2)Setting up SSL certificates...$(tput sgr0)"

    # Ensure the target directory exists and set permissions
    mkdir -p "${HAPROXY_PATH}/certs"
    chmod 755 "${HAPROXY_PATH}/certs"

    # Run Docker container to generate SSL certificates
    if docker run --rm -v "${HAPROXY_PATH}/certs:/certs" -e SSL_SUBJECT="${DOMAIN_NAME}" -e SSL_IP="${SERVER_IP}" paulczar/omgwtfssl > /dev/null 2>&1; then
        echo "$(tput setaf 2)SSL certificates created successfully.$(tput sgr0)"
        # Concatenate key and cert into a single bundle
        sudo cat "${HAPROXY_PATH}/certs/key.pem" "${HAPROXY_PATH}/certs/cert.pem" > "${HAPROXY_PATH}/certs/cert-bundle.pem"
    else
        echo "$(tput setaf 1)Failed to create SSL certificates. Check Docker and volume permissions.$(tput sgr0)"
        exit 1
    fi
else
    echo "$(tput setaf 3)User-provided SSL certificate bundle already exists. Skipping setup...$(tput sgr0)"
fi

# Copy user provided certs
if [ -f "$CERT_BUNDLE_PATH" ]; then
    echo "$(tput setaf 2)Copying user-provided SSL certificates...$(tput sgr0)"
    mkdir -p "${HAPROXY_PATH}/certs"
    cp "$CERT_BUNDLE_PATH" "${HAPROXY_PATH}/certs/cert-bundle.pem"
else
    echo "$(tput setaf 3)User-provided SSL certificate bundle not found. Skipping copy...$(tput sgr0)"
fi

# Substitute environment variables into the HAProxy configuration
substitute_variables "${HAPROXY_PATH}${CONFIG_TEMPLATE}" "${HAPROXY_PATH}${CONFIG_OUTPUT}"
echo "$(tput setaf 2)HAProxy configuration file created.$(tput sgr0)"

# Validate HAProxy configuration using Docker
echo "$(tput setaf 2)Validating HAProxy configuration using Docker...$(tput sgr0)"
if docker run --rm \
    -v "${HAPROXY_PATH}${CONFIG_OUTPUT}:/usr/local/etc/haproxy/haproxy.cfg:ro" \
    -v "${HAPROXY_PATH}/certs:/etc/haproxy/certs:ro" \
    haproxy:latest haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg; then
    echo "$(tput setaf 2)Configuration is valid, deploying HAProxy...$(tput sgr0)"
else
    echo "$(tput setaf 1)Configuration validation failed, please check the HAProxy configuration file.$(tput sgr0)"
    exit 1
fi

# Run HAProxy
echo "$(tput setaf 2)Deploying HAProxy...$(tput sgr0)"
docker compose -f ${HAPROXY_PATH}/docker-compose.yml up -d

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
    docker compose -f ${DIALOQBASE_COMPOSE_FILE} --env-file ${DIALOQBASE_COMPOSE_FILE%/*}/.llamanator-dialoqbase.env up -d 2>/dev/null
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
