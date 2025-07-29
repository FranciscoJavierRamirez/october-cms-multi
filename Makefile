# Makefile
.PHONY: help start stop install clean validate

help:
	@echo "Comandos disponibles:"
	@echo "  make start     - Iniciar todo el sistema"
	@echo "  make stop      - Detener todo el sistema"
	@echo "  make install   - Instalar ambas versiones"
	@echo "  make clean     - Limpiar todo (CUIDADO)"
	@echo "  make validate  - Validar el entorno"

start:
	@./master-control.sh start-all

stop:
	@./master-control.sh stop-all

install: start
	@./master-control.sh install-all

clean:
	@read -p "¿Seguro que quieres borrar todo? [y/N]: " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		./master-control.sh stop-all; \
		docker system prune -a --volumes -f; \
		rm -rf data v3/october v4/october; \
	fi

validate:
	@./validate.sh
    