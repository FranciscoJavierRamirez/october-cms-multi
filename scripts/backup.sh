# backup.sh
#!/bin/bash

source shared/lib/common.sh

BACKUP_DIR="${PROJECT_ROOT}/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

log "Iniciando backup en $BACKUP_DIR"

# Backup de base de datos
docker exec october_postgres_shared pg_dump -U october_user october_shared \
    > "$BACKUP_DIR/database.sql"

# Backup de archivos October
for version in v3 v4; do
    if [ -d "$version/october/storage" ]; then
        tar -czf "$BACKUP_DIR/${version}-storage.tar.gz" \
            -C "$version/october" storage
    fi
done

# Backup de configuración
cp -r v3/.env v4/.env "$BACKUP_DIR/" 2>/dev/null || true

log "✓ Backup completado en $BACKUP_DIR"