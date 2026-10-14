#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# 0. Minikube (le lab est gourmand : Mimir + Loki + Tempo + 23 services de démo)
# minikube start --cpus=6 --memory=12288 --disk-size=40g

# 1. Dépôts Helm
helm repo add grafana              https://grafana.github.io/helm-charts            # Mimir
helm repo add grafana-community    https://grafana-community.github.io/helm-charts  # Loki, Tempo, Grafana
helm repo add open-telemetry       https://open-telemetry.github.io/opentelemetry-helm-charts     # Collector, démo
helm repo update

kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

# 2. Backends (ordre : stockage d'abord, collecte ensuite)
helm upgrade --install mimir grafana/mimir-distributed          -n observability -f mimir.yaml --timeout 10m
helm upgrade --install loki  grafana-community/loki             -n observability -f loki.yaml
helm upgrade --install tempo grafana-community/tempo            -n observability -f tempo.yaml

# 3. Collecte
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector -n observability -f otel-collector.yaml

# 4. Visualisation
helm upgrade --install grafana grafana-community/grafana        -n observability -f grafana.yaml

# 5. Application de démo (namespace séparé)
helm upgrade --install otel-demo open-telemetry/opentelemetry-demo -n demo --create-namespace -f otel-demo.yaml --timeout 10m

echo
echo "Grafana : minikube service -n observability grafana --url   (admin / admin)"
echo "Démo    : minikube service -n demo frontend-proxy --url"
