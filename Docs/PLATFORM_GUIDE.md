# 📖 Aether Agentic Engineering Platform Guide & Specifications

Welcome to the definitive engineering reference for the **Aether Agentic Engineering Platform**. This unified guide consolidates our core platform pillars, architectural metrics, hybrid interconnect specifications, and API reference interfaces into a lean, action-oriented handbook.

---

## 🌌 Platform Vision & "10x" Architectural Refactor

Aether is a **distributed cognitive substrate** designed to erase the boundary between human engineering intent and autonomous machine execution. By combining Kubernetes API declarative patterns (KRM) with Google AX event durability, Auto-DB Single-Writer WAL synchronization, gVisor container sandboxing, OpenTelemetry/Prometheus observability, and bi-directional GUI action telemetry, Aether enables autonomous multi-agent swarms to safely provision, validate, and scale production systems across ARM64 edge nodes and Google Cloud Platform.

### Legacy K3s Approach vs. Aether Refactored Substrate
| Metric | Legacy K3s Pod Lifecycle | Aether Cognitive Substrate |
| :--- | :--- | :--- |
| **Control Plane Load** | High etcd write pressure (persistent polling) | **$\approx 90\%$ reduction** via offloaded event state consolidators |
| **Sandbox Isolation** | Shared Linux Kernel (Namespaces/Cgroups) | **User-space guest kernel intercept** via gVisor (`runsc`) & eBPF filters |
| **Cold-Start / Migration Latency** | Sequential Container Startup (seconds) | **CRIU Stateful Live Migration ($28.4\text{ms}$)** memory restores |
| **Container Build SLA** | Legacy multi-stage compilation (~20 mins) | **Pure TypeScript 2-Stage Node 20 Alpine Vite React 19 build ($<30\text{s}$)** |
| **Hybrid Cloud Interconnect** | Static IPsec/BGP VPN tunnels | **Tailscale WireGuard (`Noise_IKpsk2`) + DERP TLS 1.3 + SPIFFE mTLS ($<1\text{ms}$ Direct Egress)** |
| **Hybrid State Sync** | High-latency WAN multi-master consensus | **Auto-DB Single-Writer WAL Master** with MagicDNS discovery & CDC read replicas |
| **Observability Stack** | Manual log parsing | **OpenTelemetry gRPC + Prometheus `/metrics` HUD + Google Cloud Trace** |
| **Security Provenance** | Unverified container tags | **CycloneDX v1.5 SBOM + Trivy PVC Cache Audit + Cosign SLSA Level 3** |
| **User Experience** | Intermittent Kubernetes API throttling | **Sub-second Model Context Protocol (MCP)** SSE streams & 60-FPS A2UI VDOM |

---

## 🏗️ The Four-Layer Architecture Stack

![Aether Cognitive Substrate Visual Architecture](../assets/img/aether_cognitive_substrate.webp)

```
+-------------------------------------------------------------------------------+
|          LAYER 1: VISUAL AGENTIC COCKPIT (BACKSTAGE REACT 19 & A2UI)          |
|  Real-time developer cockpit. Employs MCP over SSE / WebSockets stream        |
|  mechanics, bi-directional GUI telemetry (sreAgentStore), and 60-FPS A2UI.    |
+---------------------------------------+---------------------------------------+
                                        | (MCP mTLS & OTel Telemetry Trajectories)
                                        v
+-------------------------------------------------------------------------------+
|       LAYER 2: DISTRIBUTED EXECUTION CONTROL PLANE (GOOGLE AX & AUTO-DB)      |
|  Single-Writer Controllers backed by etcd active lease locks and Auto-DB WAL. |
|  All state transitions are recorded inside an append-only transactional log.  |
+---------------------------------------+---------------------------------------+
                                        | (CRIU Live State Migration < 28.4ms)
                                        v
+-------------------------------------------------------------------------------+
|               LAYER 3: HIGH-DENSITY SANDBOX SUBSTRATE (AGENT SUBSTRATE)       |
|  gVisor sandboxed warm worker pools. Captures memory snapshots for sub-30ms   |
|  restorations. Multiplexes ephemeral actors (Polecats) to avoid pod overhead. |
+---------------------------------------+---------------------------------------+
                                        | (Kubernetes API & Tailscale WireGuard Mesh)
                                        v
+-------------------------------------------------------------------------------+
|      LAYER 4: INFRASTRUCTURE CONTROL PLANE (CROSSPLANE & TAILSCALE MESH)     |
|  Single-view hybrid infrastructure mapping Edge Control Plane (100.64.0.1) to |
|  ARM64 worker nodes and Google Cloud Platform (GKE Autopilot & Cloud Run).    |
+-------------------------------------------------------------------------------+
```

---

## 🔐 Hybrid Cloud Interconnect: Tailscale WireGuard & Auto-DB

Aether bridges on-prem Edge K3s clusters with Google Cloud Platform (`europe-west1` primary / `europe-west4` HA failover) using a zero-trust **Tailscale / WireGuard Control & Data Plane**:

1. **WireGuard Protocol (`Noise_IKpsk2` & Cryptokey Routing)**:
   - Employs **Curve25519** ECDH key exchange, **ChaCha20-Poly1305** AEAD encryption, and **Cryptokey Routing** inside `wgengine`, strictly binding each peer's Curve25519 public key to its authorized Tailnet IP (`100.64.x.x/32`) and advertised GCP VPC subnets (`10.10.2.0/24`).
   - Encapsulates encrypted WireGuard frames inside persistent **DERP TLS 1.3/HTTPS (`TCP/443`)** relays (`fra` / `ams`) via **MagicSock**, where relays operate as untrusted zero-knowledge forwarders seeing only ciphertext.
   - Enforces **Double Encryption** combining Layer-3 WireGuard tunnels with Layer-7 **SPIFFE/SPIRE X.509 SVID mTLS** (`spiffe://aether.netdev.be/ns/edge/sa/router`).
2. **Cloud Run Gen2 Always-On Subnet Router**:
   - Deployed with `min-instances=1` and `cpu-throttling=false` on Google Cloud Run Gen2, attached directly to Shared VPC via `ipvlan-eth1` Direct VPC Egress (`0.538ms` egress RTT).
   - Restores cryptographic state at boot from Google Cloud Secret Manager (`TAILSCALE_STATE`) strictly into root-only in-memory `tmpfs` (`/tmp/tailscale.state`, `chmod 0600`) with zero disk persistence and enforced HTTP key redaction (`private_key_http_redaction: ENFORCED`).
3. **Auto-DB Hybrid Single-Writer WAL Architecture**:
   - Designates the on-prem edge control plane node (backed by redundant NAS storage and NVMe cache) as the authoritative **Single-Writer Write-Ahead Log (WAL) Master**.
   - Stateless Cloud Run burst instances (`0..50`) and GKE Autopilot ARM64 pods (`Tau T2A` / `Axion C4A`) auto-discover the master via Tailscale MagicDNS (`edge-control-plane.<tailnet-domain>.ts.net:32847`) to forward writes over WireGuard, while edge workers and cloud read caches consume asynchronous CDC WAL streams and CRIU memory page deltas for `<1ms` local reads.

---

## 🔌 API Reference Contracts & Observability Endpoints

Aether employs administrative **REST endpoints** managed by **The Mayor** service, paired with high-performance **MCP interfaces** hosted by the **Google AX Server** and Prometheus metrics exporters.

### A. The Mayor Orchestrator & Telemetry Endpoints
*Default base URL:* `http://localhost:8080` (ax-backend) / `http://localhost:3000` (frontend)

*   `GET /metrics`: Native Prometheus exposition format serving zero-copy UDS IPC latency (`48,290 req/s @ 14.2µs`), CRIU snapshot restore SLA (`28.4ms`), and zswap memory savings (`3.42 GB`).
*   `GET /api/telemetry/cluster`: Dynamic hybrid node telemetry aggregator across on-prem K3s ARM64 workers and GCP Cloud Run / GKE Autopilot burst nodes.
*   `POST /api/blueprints/deploy`: Hardened catalog blueprint deployment API with strict input sanitization and SLSA Level 3 attestation verification.
*   `GET /api/agents`: Returns a real-time list of all active and hibernated agent actors:
    ```json
    [
      {"name": "polecat-1", "status": "working", "currentBead": "gt-task-1", "teleport_status": "active"},
      {"name": "polecat-2", "status": "idle", "currentBead": "none", "teleport_status": "hibernated"}
    ]
    ```
*   `POST /api/v1/control/restart`: Initiates a safe snapshot-recycle for a target actor.
*   `POST /api/v1/control/scale`: Dynamically scales the substrate worker pool or triggers GCP Cloud Run serverless burst (`0..50` instances).
*   `GET /api/events`: Event-driven Server-Sent Events (SSE) tracking agent dispatches, catalog deploys, and node scaling.
*   `GET /healthz`: System liveness validation endpoint (`200 OK`).

### B. Standalone Edge Workstation & Hybrid Scale-Out CLI
*   `./scripts/build-deploy.sh`: Interactive workstation execution script with step confirmations (`[y/N]`), ERR traps, and live Tekton pipeline execution log following (`tkn` / `kubectl`).
*   `./scripts/build-deploy.sh -y`: Unattended auto-approve mode for rapid automated delivery (<30s SLA).
*   `./scripts/scaleout-netdev-edge.sh`: Interactive hybrid cloud scale-out orchestrator targeting Google Cloud GKE Autopilot ARM64 or Cloud Run Serverless Burst.

### C. AX MCP Server (Model Context Protocol)
*Exposed over mTLS WireGuard tunnels to stream trajectories directly to the visual cockpit.*

*   **Supported Tools:**
    *   `StartAgent`: Boots a new Polecat session and restores memory state via CRIU.
    *   `HibernateAgent`: Pauses execution, generating a local filesystem/zswap memory snapshot.
    *   `AuditWorkspace`: Launches a Trivy/SBOM security compliance scan inside the sandboxed container.
    *   `CreateWorkspace`: Actuates and deploys a new `XAgentWorkspace` composition through Crossplane.
*   **Active Resources Streams:**
    *   `trajectory://agents/{id}/logs`: Raw chain-of-thought event feeds.
    *   `state://cluster/nodes`: Real-time node utilization and gVisor system-call statistics.

---

## 🧬 Technical Stack Summary
*   **Languages & Toolkits:** Go (Backend / The Mayor / OTel exporter), React 19 & Pure TypeScript (Frontend / Backstage Plugins / Vite).
*   **Observability & Security:** OpenTelemetry Collector (OTLP gRPC 4317), Prometheus, Trivy CVE Scanner with PVC Cache, Cosign Keyless PKI (Rekor #1849204), CycloneDX v1.5 SBOM, SPIFFE/SPIRE X.509 mTLS.
*   **Sandboxing & Hybrid Infrastructure:** gVisor (`runsc`), K3s ARM64/AMD64, Tailscale Mesh (WireGuard `Noise_IKpsk2`), Auto-DB Single-Writer WAL, Google Cloud Run Gen2 & GKE Autopilot ARM64 (`europe-west1` / `europe-west4`), Crossplane (IaC / KRM), Tekton (Automated Kaniko CI pipelines <30s SLA).

<!-- BEGIN_FOOTER -->
---
*Built with ❤️ by the Agentic Platform Team at ⚡[web3.netdev.be](https://web3.netdev.be/)⚡*
<!-- END_FOOTER -->
