# Makefile
.PHONY: help setup up down install install-v3 install-v4 logs logs-v3 logs-v4 shell-v3 shell-v4 clean validate

# Variables
COMPOSE_FILE = docker-compose.yml
COMPOSE_DEV = --profile dev

help: ## Mostrar ayuda
	@echo "October CMS Multi-Version Development Environment"
	@echo ""
	@echo "Comandos disponibles:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Configuración inicial del proyecto
	@./scripts/setup.sh

up: ## Iniciar todos los servicios
	@docker-compose -f $(COMPOSE_FILE) $(COMPOSE_DEV) up -d
	@echo "Servicios iniciados:"
	@echo "  October v3.7: http://v3.october.local"
	@echo "  October v4.0: http://v4.october.local"
	@echo "  Adminer:      http://localhost:8080"
	@echo "  MailHog:      http://localhost:8025"

down: ## Detener todos los servicios
	@docker-compose -f $(COMPOSE_FILE) down

install: install-v3 install-v4 ## Instalar ambas versiones de October

install-v3: ## Instalar October CMS v3.7
	@./scripts/install.sh v3

install-v4: ## Instalar October CMS v4.0
	@./scripts/install.sh v4

logs: ## Ver logs de todos los servicios
	@docker-compose -f $(COMPOSE_FILE) logs -f

logs-v3: ## Ver logs de October v3.7
	@docker-compose -f $(COMPOSE_FILE) logs -f october-v3

logs-v4: ## Ver logs de October v4.0
	@docker-compose -f $(COMPOSE_FILE) logs -f october-v4

shell-v3: ## Acceder al shell de October v3.7
	@docker exec -it october_v3 /bin/bash

shell-v4: ## Acceder al shell de October v4.0
	@docker exec -it october_v4 /bin/bash

artisan-v3: ## Ejecutar comando Artisan en v3.7 (ej: make artisan-v3 CMD="make:plugin Acme.Blog")
	@docker exec -it october_v3 php artisan $(CMD)

artisan-v4: ## Ejecutar comando Artisan en v4.0 (ej: make artisan-v4 CMD="make:plugin Acme.Blog")
	@docker exec -it october_v4 php artisan $(CMD)

validate: ## Validar el entorno
	@./scripts/validate.sh

clean: ## Limpiar todo (CUIDADO: borra todos los datos)
	@read -p "¿Estás seguro de que quieres borrar todos los datos? [y/N]: " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose -f $(COMPOSE_FILE) down -v; \
		docker system prune -a -f; \
		rm -rf volumes/october-v3/* volumes/october-v4/* volumes/data/*; \
		echo "Limpieza completada"; \
	fi

rebuild: ## Reconstruir containers
	@docker-compose -f $(COMPOSE_FILE) build --no-cache

status: ## Mostrar estado de los servicios
	@docker-compose -f $(COMPOSE_FILE) ps
    