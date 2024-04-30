$dockerDaemonMode=(docker version -f '{{.Server.Os}}')

if ($dockerDaemonMode -ne "linux")
{
	Write-Error "Use docker desktop in linux mode"
	exit 1
}
# Load env from .env file
$envContentLines=Get-Content .env

ForEach($line in $envContentLines)
{
	if ([string]::IsNullOrWhiteSpace($line) -Or $line.Contains("#"))
	{
		continue
	}
	$name, $value = $line.split("=")

	Set-Item -Path Env:\$name -Value $value
}

$dockerNetworkName="llamanator"

docker network inspect $dockerNetworkName 2>&1 | out-null

if ($LastExitCode) 
{
	Write-Host "Creating private network..."
	docker network create $dockerNetworkName
} else
{
	Write-Host "Private network already exists. Skipping creation..."
}

if ($env:ENABLE_OLLAMACPU -eq "true")
{
	Write-Host "Deploying Ollama CPU..."
	docker compose -f $env:OLLAMACPU_COMPOSE_FILE up -d
} else
{
	Write-Host "Skipping Ollama CPU..."
}

if ($env:ENABLE_OLLAMAGPU -eq "true")
{
	Write-Host "Deploying Ollama GPU..."
	docker compose -f $env:OLLAMAGPU_COMPOSE_FILE up -d
} else
{
	Write-Host "Skipping Ollama GPU..."
}

$models=$env:OLLAMA_MODELS.Split(" ")

Foreach ($model in $models)
{
	write-host "docker exec -it ollama ollama pull $model"
	docker exec -it ollama ollama pull "$model"
}

if ($env:ENABLE_DIALOQBASE -eq "true")
{
	Write-Host "Deploying Dialogbase..."
	get-content "$env:DIALOQBASE_SOURCE_PATH/.env" > "$env:DIALOQBASE_SOURCE_PATH/.llamanator-dialoqbase.env"
	docker compose -f "$env:DIALOQBASE_COMPOSE_FILE" --env-file "$env:DIALOQBASE_SOURCE_PATH/.llamanator-dialoqbase.env" up -d 2>&1 | out-null
} else
{
	Write-Host "Skipping Dialogbase..."
}

if ($env:ENABLE_OPENWEBUI -eq "true")
{
	Write-Host "Deploying OpenWebUI..."
	get-content "$env:OPENWEBUI_SOURCE_PATH/.env" > "$env:OPENWEBUI_SOURCE_PATH/.llamanator-dialoqbase.env"
	docker compose -f "$env:OPENWEBUI_COMPOSE_FILE" --env-file "$env:OPENWEBUI_SOURCE_PATH/.llamanator-dialoqbase.env" up -d 2>&1 | out-null
} else
{
	Write-Host "Skipping OpenWebUI..."
}
