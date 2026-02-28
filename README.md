# 🛡️ Sentinel-PQC: Post-Quantum Cryptography Admission Controller

A Kubernetes-native policy framework designed to enforce White House NSM-10 and NIST Post-Quantum Cryptography (PQC) transition mandates across enterprise clusters. 

Sentinel-PQC intercepts cryptographic asset generation at the Kubernetes API level, auditing and blocking legacy algorithms (like RSA) to ensure all newly provisioned certificates and TLS secrets are quantum-resistant.

## 📖 Overview
As quantum computing advances, legacy cryptographic algorithms (RSA, standard Diffie-Hellman) are vulnerable to "Store Now, Decrypt Later" (SNDL) attacks. The U.S. Government (via NSM-10) mandates a transition to quantum-resistant cryptography. 

**Sentinel-PQC** acts as an automated, zero-trust infrastructure guardrail. Built on top of **Kyverno** and seamlessly integrated with **cert-manager**, this framework ensures that developers cannot accidentally deploy non-compliant cryptography into production environments.

### Key Features
* **NIST PQC Enforcement:** Explicitly allows only transition-state (ECC) and finalized NIST PQC algorithms (FIPS 203/ML-KEM, FIPS 204/ML-DSA, FIPS 205/SLH-DSA).
* **Dual-Mode Operation:** Supports `Audit` mode for day-one compliance mapping (zero downtime) and `Enforce` mode for active blocking.
* **Dynamic Scoping:** Granular include/exclude lists to isolate legacy namespaces or third-party vendor applications from enforcement.
* **Observability Ready:** Automatically generates Kubernetes Policy Reports for integration with Prometheus and Grafana compliance dashboards.

---

## 🏗️ Architecture

1. **The Request:** A developer or CI/CD pipeline requests a new TLS Certificate via `cert-manager`.
2. **The Intercept:** The Kubernetes API server hands the request to the Sentinel-PQC Mutating/Validating Webhook (powered by Kyverno).
3. **The Evaluation:** The framework inspects the `.spec.privateKey.algorithm` against the allowed enterprise standards defined in `values.yaml`.
4. **The Action:** If the algorithm is legacy (e.g., `RSA`), the request is immediately rejected with a `FATAL` compliance error.

---

## 🚀 Quick Start

### Prerequisites
* Kubernetes Cluster (v1.24+)
* Helm v3
* [cert-manager](https://cert-manager.io/docs/installation/) installed
* [Kyverno](https://kyverno.io/docs/installation/) (v1.17+) installed

### 1. Install the Kyverno Engine
```bash
helm repo add kyverno [https://kyverno.github.io/kyverno/](https://kyverno.github.io/kyverno/)
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

### 2. Deploy the Sentinel-PQC Framework
Deploy the framework in `Audit` mode (default) to log violations without breaking existing deployments:
```bash
helm upgrade --install sentinel-pqc-framework ./sentinel-pqc-chart -n security-tools --create-namespace
```

To deploy in **active blocking** mode:
```bash
helm upgrade --install sentinel-pqc-framework ./sentinel-pqc-chart -n security-tools --set mode="Enforce"
```

---

## 🧪 Validating the Guardrail

Once deployed in `Enforce` mode, test the architecture by attempting to deploy a vulnerable RSA certificate.

**1. Create `bad-cert.yaml`:**
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: legacy-rsa-cert
  namespace: default
spec:
  secretName: legacy-rsa-tls
  commonName: "legacy.example.com"
  issuerRef:
    name: ca-issuer
    kind: ClusterIssuer
  privateKey:
    algorithm: RSA  # <-- This triggers the PQC block
    size: 2048
```

**2. Apply the manifest:**
```bash
kubectl apply -f bad-cert.yaml
```

**3. Expected Output:**
```text
Error from server: error when creating "bad-cert.yaml": admission webhook "validate.kyverno.svc-fail" denied the request: 
resource Certificate/default/legacy-rsa-cert was blocked due to the following policies:
sentinel-pqc-enforce-crypto-readiness:
  block-legacy-rsa-certs: '[Sentinel-PQC Admission Control] FATAL: The requested algorithm does not meet NIST Post-Quantum Cryptography transition requirements. Allowed algorithms: ECDSA, Ed25519, ML-KEM, ML-DSA, SLH-DSA.'
```

---

## ⚙️ Configuration (`values.yaml`)

You can customize the allowed algorithms and namespace scope to fit your organization's specific cryptographic transition timeline:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mode` | `Audit` (log only) or `Enforce` (block) | `"Audit"` |
| `cryptoStandards.allowedAlgorithms` | List of approved algorithms | `[ECDSA, Ed25519, ML-KEM, ML-DSA, SLH-DSA]` |
| `scope.excludeNamespaces` | Namespaces exempt from PQC rules | `["kube-system"]` |
| `features.certManager.enabled` | Scan `Certificate` custom resources | `true` |



## ⚡ Operational & Performance Considerations

Deploying a Validating Webhook into a Kubernetes cluster introduces network hops to the API server's request path. If not architected correctly, this can cause latency and API throttling. 

Sentinel-PQC is engineered with strict guardrails to ensure zero degradation to cluster performance:



### 1. Granular Resource Scoping (Zero Pod Latency)
Unlike broad admission controllers that intercept every `Pod` or `ConfigMap` creation, Sentinel-PQC is explicitly bound to cryptographic resources (`cert-manager.io/v1/Certificate` and `v1/Secret`). Because certificate generation is a low-frequency event, the webhook sits idle for 99.9% of cluster activity, adding absolutely zero milliseconds of latency to standard application deployments.

### 2. Control Plane Protection (Namespace Bypasses)
The framework defaults to excluding critical namespaces (e.g., `kube-system`). This ensures that if the Kyverno engine experiences downtime or extreme latency, core Kubernetes networking components (like CoreDNS or the API server itself) are never blocked from rotating their internal certificates. 

### 3. High Availability (HA) Readiness
For production workloads handling high-throughput certificate issuance (e.g., dynamic Istio mTLS environments), the underlying Kyverno engine must be deployed with `replicaCount: 3` and an active Horizontal Pod Autoscaler (HPA). This prevents the webhook from becoming a bottleneck during sudden cryptographic threshold spikes.



## 📊 Observability & Compliance Dashboards

Sentinel-PQC includes a pre-configured Grafana dashboard to visualize cryptographic compliance across your cluster.

### Monitoring Architecture
Because Kyverno and Prometheus often reside in isolated namespaces, Sentinel-PQC utilizes a **Shadow Service Bridge**. This creates a local metrics endpoint within the `monitoring` namespace that securely proxies telemetry from the Kyverno engine.

### Accessing the Dashboard
1. Ensure the Prometheus stack is running.
2. The dashboard is automatically loaded via a ConfigMap in the `sentinel-pqc-chart`.
3. Metrics tracked:
   * **Blocked Violations:** Real-time count of denied RSA/legacy requests.
   * **Policy Pass/Fail Ratio:** Percentage of cluster secrets meeting PQC standards.
   * **Top Violators:** Namespaces attempting the most non-compliant deployments.

