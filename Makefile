DOCKER_COMPOSE_PROD = docker-compose -f docker-compose.yml
PROJECT_ROOT = ..

help: ## Mostrar esta ayuda
	@echo "Comandos disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

# Producción
prod: ## Iniciar entorno de producción
	@echo "🚀 Iniciando entorno de producción..."
	$(DOCKER_COMPOSE_PROD) up -d

prod-build: ## Construir e iniciar entorno de producción
	$(DOCKER_COMPOSE_PROD) up --build -d --force-recreate

prod-logs: ## Ver logs del entorno de producción
	$(DOCKER_COMPOSE_PROD) logs -f

prod-stop: ## Detener entorno de producción
	$(DOCKER_COMPOSE_PROD) down -v --remove-orphans
