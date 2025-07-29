# test.sh
#!/bin/bash

source shared/lib/common.sh

run_test() {
    local name=$1
    local cmd=$2
    
    echo -n "Testing $name... "
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        return 1
    fi
}

# Tests de infraestructura
run_test "PostgreSQL" "docker exec october_postgres_shared pg_isready"
run_test "Redis" "docker exec october_redis_shared redis-cli ping"

# Tests de October
for version in v3 v4; do
    domain="${version}.october.local"
    run_test "$domain frontend" "curl -f http://$domain"
    run_test "$domain backend" "curl -f http://$domain/backend"
done