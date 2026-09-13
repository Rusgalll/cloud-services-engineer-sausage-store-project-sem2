#!/usr/bin/env bash
set -euo pipefail

component="${1:?Pass backend, frontend or backend-report}"
image="${2:?Pass the built image tag}"
container="sausage-ci-app"
network="sausage-ci"
mongodb="sausage-ci-mongodb"

case "$component" in
  backend|frontend|backend-report) ;;
  *) echo "Unknown component: $component" >&2; exit 1 ;;
esac

cleanup() {
  result=$?
  if [ "$result" -ne 0 ]; then
    docker logs "$container" 2>&1 || true
    docker logs "$mongodb" 2>&1 || true
  fi
  docker rm -f "$container" >/dev/null 2>&1 || true
  docker rm -f "$mongodb" >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
  exit "$result"
}
trap cleanup EXIT

wait_for_http() {
  curl --fail --silent --show-error \
    --retry 30 --retry-all-errors --retry-delay 2 \
    --retry-max-time 120 --max-time 5 "$1"
}

docker network create "$network" >/dev/null

if [ "$component" != "frontend" ]; then
  docker run --detach --name "$mongodb" --network "$network" mongo:7.0 >/dev/null
  for attempt in {1..30}; do
    if docker exec "$mongodb" mongosh --quiet --eval 'db.adminCommand({ ping: 1 })' >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done
  docker exec "$mongodb" mongosh --quiet --eval 'db.adminCommand({ ping: 1 })' >/dev/null
fi

case "$component" in
  backend)
    # H2 позволяет проверить образ независимо от миграций PostgreSQL, которые будут добавлены на этапе 2
    docker run --detach --name "$container" --network "$network" \
      --publish 127.0.0.1:18080:8080 \
      --env 'SPRING_DATASOURCE_URL=jdbc:h2:mem:smoke;DB_CLOSE_DELAY=-1' \
      --env SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.h2.Driver \
      --env SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.H2Dialect \
      --env SPRING_JPA_HIBERNATE_DDL_AUTO=create-drop \
      --env SPRING_DATASOURCE_USERNAME=sa \
      --env SPRING_DATASOURCE_PASSWORD=smoke \
      --env SPRING_FLYWAY_ENABLED=false \
      --env SPRING_CLOUD_VAULT_ENABLED=false \
      --env "SPRING_DATA_MONGODB_URI=mongodb://$mongodb:27017/sausage-store" \
      "$image" >/dev/null

    wait_for_http http://127.0.0.1:18080/actuator/health | jq --exit-status '.status == "UP"'
    curl --fail --silent --show-error http://127.0.0.1:18080/api/products \
      | jq --exit-status 'length == 6'
    curl --fail --silent --show-error \
      --header 'Content-Type: application/json' \
      --data '{"productOrders":[{"product":{"id":1},"quantity":2}]}' \
      http://127.0.0.1:18080/api/orders \
      | jq --exit-status '.status == "PAID" and .totalOrderPrice == 640'
    ;;
  frontend)
    docker run --detach --name "$container" --network "$network" \
      --publish 127.0.0.1:18080:80 \
      --env BACKEND_URL=http://127.0.0.1:8080 \
      "$image" >/dev/null

    page="$(wait_for_http http://127.0.0.1:18080/)"
    [[ "$page" == *"<app-root>"* ]]
    docker exec "$container" nginx -t
    ;;
  backend-report)
    docker run --detach --name "$container" --network "$network" \
      --publish 127.0.0.1:18080:8080 \
      --env PORT=8080 \
      --env "DB=mongodb://$mongodb:27017/sausage-store" \
      "$image" >/dev/null

    wait_for_http http://127.0.0.1:18080/api/v1/health | jq --exit-status '.data == "Ok"'
    ;;
esac

echo "Smoke test passed: $component"
