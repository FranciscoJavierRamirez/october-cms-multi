.PHONY: help up down install status logs clean shell-v3 shell-v4

# Variables
DC = docker-compose
V3_CONTAINER = october_v3
V4_CONTAINER = october_v4

# Colores
GREEN = \033[0;32m
BLUE = \033[0;34m
NC = \033[0m

help: ## Mostrar ayuda
	@echo "$(BLUE)October CMS Multi-Version Development$(NC)"
	@echo ""
	@echo "Comandos disponibles:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Iniciar todos los servicios
	@echo "$(BLUE)Iniciando servicios...$(NC)"
	@$(DC) up -d
	@echo ""
	@echo "$(GREEN)Servicios iniciados:$(NC)"
	@echo "  October v3.7: http://v3.october.local"
	@echo "  October v4.0: http://v4.october.local"
	@echo "  Adminer:      http://localhost:8080"
	@echo "  MailHog:      http://localhost:8025"

down: ## Detener todos los servicios
	@echo "$(BLUE)Deteniendo servicios...$(NC)"
	@$(DC) down
	@echo "$(GREEN)✓ Servicios detenidos$(NC)"

install: ## Instalar October CMS en ambas versiones
	@echo "$(BLUE)Instalando October CMS...$(NC)"
	@./scripts/install.sh
	@echo "$(GREEN)✓ Instalación completada$(NC)"

install-v3: ## Instalar solo October v3.7
	@./scripts/install.sh v3

install-v4: ## Instalar solo October v4.0
	@./scripts/install.sh v4

status: ## Ver estado de los servicios
	@echo "$(BLUE)Estado de los servicios:$(NC)"
	@$(DC) ps

logs: ## Ver logs de todos los servicios
	@$(DC) logs -f

logs-v3: ## Ver logs de October v3.7
	@$(DC) logs -f october-v3

logs-v4: ## Ver logs de October v4.0
	@$(DC) logs -f october-v4

shell-v3: ## Acceder al shell de October v3.7
	@docker exec -it $(V3_CONTAINER) /bin/bash

shell-v4: ## Acceder al shell de October v4.0
	@docker exec -it $(V4_CONTAINER) /bin/bash

artisan-v3: ## Ejecutar Artisan en v3.7 (uso: make artisan-v3 CMD="migrate")
	@docker exec -it $(V3_CONTAINER) php artisan $(CMD)

artisan-v4: ## Ejecutar Artisan en v4.0 (uso: make artisan-v4 CMD="migrate")
	@docker exec -it $(V4_CONTAINER) php artisan $(CMD)

clean: ## Limpiar todo (CUIDADO: borra datos)
	@read -p "¿Seguro que quieres borrar todo? [y/N]: " -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(DC) down -v; \
		rm -rf volumes/v3/* volumes/v4/* volumes/data/*; \
		echo "$(GREEN)✓ Limpieza completada$(NC)"; \
	fi

setup: ## Configuración inicial del proyecto
	@echo "$(BLUE)Configurando proyecto...$(NC)"
	@mkdir -p volumes/{v3,v4,data/{postgres,redis,logs/nginx}}
	@cp -n .env.example .env 2>/dev/null || true
	@chmod +x scripts/*.sh
	@./scripts/setup-hosts.sh
	@echo "$(GREEN)✓ Configuración completada$(NC)"

restart: down up ## Reiniciar todos los servicios

rebuild: ## Reconstruir containers
	@echo "$(BLUE)Reconstruyendo containers...$(NC)"
	@$(DC) build --no-cache
	@echo "$(GREEN)✓ Containers reconstruidos$(NC)"

test: ## Verificar que todo funciona
	@echo "$(BLUE)Verificando servicios...$(NC)"
	@echo -n "PostgreSQL: "; docker exec october_postgres pg_isready -U october_user >/dev/null 2>&1 && echo "$(GREEN)✓$(NC)" || echo "✗"
	@echo -n "Redis: "; docker exec october_redis redis-cli ping >/dev/null 2>&1 && echo "$(GREEN)✓$(NC)" || echo "✗"
	@echo -n "October v3.7: "; curl -sf http://v3.october.local >/dev/null 2>&1 && echo "$(GREEN)✓$(NC)" || echo "✗"
	@echo -n "October v4.0: "; curl -sf http://v4.october.local >/dev/null 2>&1 && echo "$(GREEN)✓$(NC)" || echo "✗"