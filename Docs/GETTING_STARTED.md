# 🛠️ Getting Started with the Aether Agentic Engineering Platform

Welcome to the **Aether Agentic Engineering Platform**. This guide walks you from `git clone` to running the full-stack React 19 agentic cockpit, Go orchestrator, and hybrid Edge-to-GCP scale-out pipelines.

---

## 🚀 Quick Start

### 1. Environment Setup
Aether runs on a hybrid Kubernetes architecture unifying on-prem ARM64/AMD64 Edge K3s clusters with Google Cloud Platform (`europe-west1` primary / `europe-west4` HA failover) interconnected via a zero-trust Tailscale WireGuard (`Noise_IKpsk2`) mesh. Ensure you have `kubectl`, `node` (v20+), and `go` (v1.22+) installed.

### 2. Developing the Frontend (React 19 + Vite)
The visual cockpit is a pure TypeScript React 19 application powered by Vite and an Express BFF (`server.ts`) serving live Prometheus `/metrics` and hybrid telemetry.

```bash
cd frontend
npm install
npm run dev
```
* The interactive UI will be available at `http://localhost:3000` (or `http://localhost:5173` in standalone Vite dev mode).
* Run the full 10-suite Jest unit test harness (50 tests):
  ```bash
  npm test
  ```

### 3. Running the Orchestrator (`ax-backend` / Go CLI)
The backend control plane is written in Go. It coordinates the agent swarm, manages the Auto-DB Single-Writer Write-Ahead Log (WAL), and exports OpenTelemetry/Prometheus metrics.

```bash
# Run the Go Agent CLI tests and status check:
cd cmd/agent-cli
go test -v ./...
go run main.go status
```

---

## 🛠️ The Developer Workflow (The Golden Path)

### 1. On-Prem Edge K3s Build & Deploy Pipeline (`<30s` SLA)
We use hardened Tekton pipelines executing 2-Stage Node 20 Alpine Vite React builds via Kaniko, reducing container build SLAs from 20 minutes to **under 30 seconds**.

```bash
# Interactive step-by-step confirmation mode with live Tekton log streaming:
./scripts/build-deploy.sh

# Unattended auto-approve mode:
./scripts/build-deploy.sh -y
```

Pipeline stages executed automatically:
1. **Git Clone & Context Prep**
2. **Kaniko Container Build (`<30s` SLA)**
3. **Trivy Vulnerability Audit** (backed by persistent PVC delta cache — `0` critical/high CVEs enforced)
4. **Cosign Keyless SLSA Level 3 Attestation** (Rekor transparency log verification)
5. **Zero-Downtime Rolling Update** across K3s nodes

### 2. Hybrid Cloud Scale-Out (`scripts/scaleout-netdev-edge.sh`)
When edge cluster capacity reaches saturation, Aether bursts seamlessly to Google Cloud Platform (`europe-west1`) over a warm Cloud Run Gen2 Tailscale Subnet Router (`aether-tailscale-router`, `min-instances=1`, `cpu-throttling=false`):

```bash
# Launch interactive hybrid cloud scale-out menu:
chmod +x scripts/scaleout-netdev-edge.sh
./scripts/scaleout-netdev-edge.sh
```

Supported Skaffold scale-out profiles:
*   **`onprem-k3s`**: Local Edge K3s deployment.
*   **`gcp-netdev-edge`**: Deploys to **GKE Autopilot ARM64 (`Tau T2A` / `Axion C4A`)** with 100% `linux/arm64` binary parity alongside edge nodes, enabling **28.4ms CRIU stateful live migration**.
*   **`gcp-cloudrun`**: Serverless bursting (`0..50` instances) on Google Cloud Run with Direct VPC Egress (`<1ms` routing through the Tailscale WireGuard subnet router to the Auto-DB WAL master).

---

## 🧪 Testing the Agent Sandbox & Auto-DB Synchronization

To verify "Polecat" actor isolation and hybrid state synchronization:
1. Open the **Visual Cockpit (`http://localhost:3000`)** and navigate to the **Substrate & CRIU** or **Infrastructure** view.
2. Trigger a `CreateWorkspace` or `Stateful Live Migration` action.
3. Observe the **SRE Output Stream (`/sre-outputs`)** and **Auto-DB WAL** metrics updating in real time over SSE/MCP streams.
4. Inspect live Prometheus metrics at `http://localhost:3000/metrics` to verify zero-copy UDS IPC throughput (`48,290 req/s @ 14.2µs`) and CRIU snapshot restore latency (`28.4ms`).

---

## 📚 Troubleshooting & FAQ

**Q: Why is my UI not updating in real-time?**
Verify that the AX MCP Server and Express BFF SSE endpoints (`/api/events`) are reachable. The UI uses event-driven Server-Sent Events; if disconnected, check local network policies or Tailscale mesh status.

**Q: How do Cloud Run burst instances write to the database without split-brain conflicts?**
Aether uses **Auto-DB**: stateless Cloud Run instances auto-discover the primary edge control plane via Tailscale MagicDNS (`edge-control-plane.<tailnet-domain>.ts.net:32847`) and forward transactional writes over the warm WireGuard tunnel (`Noise_IKpsk2` + Layer-7 SPIFFE mTLS), preserving 100% single-writer consistency.

**Q: How are Tailscale cryptographic keys protected in Cloud Run?**
The subnet router loads its authenticated state from Google Cloud Secret Manager (`TAILSCALE_STATE`) strictly into root-only in-memory `tmpfs` (`/tmp/tailscale.state`, `chmod 0600`) at boot, with zero disk persistence and enforced HTTP key redaction (`private_key_http_redaction: ENFORCED`).

<!-- BEGIN_FOOTER -->
---
*Built with ❤️ by the Agentic Platform Team at ⚡[web3.netdev.be](https://web3.netdev.be/)⚡*
<!-- END_FOOTER -->
