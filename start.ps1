# PowerShell script to start Rootly services

Write-Host "Starting Rootly services..." -ForegroundColor Green

# Check if Docker is available
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker not found" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command "docker compose" -ErrorAction SilentlyContinue)) {
    Write-Host "Error: docker compose not available" -ForegroundColor Red
    exit 1
}

# Check if services are running
$runningServices = docker compose ps --format json 2>$null | ConvertFrom-Json | Where-Object { $_.State -eq "running" }

if ($runningServices) {
    Write-Host "Stopping existing services..." -ForegroundColor Yellow
    docker compose down
}

Write-Host "Starting services..." -ForegroundColor Green
docker compose up -d --build

Write-Host ""
Write-Host "Service status:" -ForegroundColor Cyan
docker compose ps

Write-Host ""
Write-Host "Health check URLs:" -ForegroundColor Cyan
Write-Host "  Frontend SSR: http://localhost:3001" -ForegroundColor White
Write-Host "  API Gateway: http://localhost:8080" -ForegroundColor White
Write-Host "  Analytics: http://localhost:8000" -ForegroundColor White
Write-Host "  Authentication: http://localhost:8001" -ForegroundColor White
Write-Host "  Data Management: http://localhost:8002" -ForegroundColor White
Write-Host "  Plant Management: http://localhost:8003" -ForegroundColor White
Write-Host "  InfluxDB: http://localhost:8086" -ForegroundColor White
Write-Host "  MinIO: http://localhost:9001" -ForegroundColor White
Write-Host "  GraphQL Playground: http://localhost:8080/graphql" -ForegroundColor White
