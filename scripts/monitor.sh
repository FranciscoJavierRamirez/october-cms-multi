# monitor.sh
#!/bin/bash

source shared/lib/common.sh

monitor_service() {
    local name=$1
    local container=$2
    
    if docker ps | grep -q "$container.*Up"; then
        echo -e "${GREEN}✓${NC} $name"
        docker stats --no-stream "$container" | tail -n 1
    else
        echo -e "${RED}✗${NC} $name - No está corriendo"
    fi
}

while true; do
    clear
    echo -e "${BLUE}=== October CMS Monitor ===${NC}"
    echo "$(date)"
    echo ""
    
    monitor_service "PostgreSQL" "october_postgres_shared"
    monitor_service "Redis" "october_redis_shared"
    monitor_service "NGINX" "october_nginx_shared"
    monitor_service "October v3.7" "october_v3_app"
    monitor_service "October v4.0" "october_v4_app"
    
    echo ""
    echo "Presiona Ctrl+C para salir"
    sleep 5
done