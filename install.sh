#!/bin/bash
# Sentinel-PQC Automated Installer

echo "🛡️ Starting Sentinel-PQC Installation..."

# 1. Get the Kyverno Pod IP for the Monitoring Bridge
echo "🔍 Finding Kyverno Metrics Endpoint..."
KYVERNO_IP=$(kubectl get pod -n kyverno -l app.kubernetes.io/component=admission-controller -o jsonpath='{.items[0].status.podIP}')

if [ -z "$KYVERNO_IP" ]; then
    echo "❌ Error: Could not find Kyverno Pod. Is Kyverno installed?"
    exit 1
fi

echo "✅ Found Kyverno IP: $KYVERNO_IP"

# 2. Deploy the Helm Chart
echo "🚀 Deploying Sentinel-PQC Helm Chart..."
helm upgrade --install sentinel-pqc ./sentinel-pqc-chart \
  -n monitoring \
  --set monitoring.kyvernoPodIP="$KYVERNO_IP" \
  --set mode="Enforce"

echo "📊 Sentinel-PQC is live! Check your Grafana dashboard at http://localhost:3000"
