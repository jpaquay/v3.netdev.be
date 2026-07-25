# 🛠️ Getting Started with Aether

Welcome to the Aether Agent Platform. This guide will get you from `git clone` to a running agentic cockpit.

## 🚀 Quick Start

### 1. Environment Setup
Aether runs on a hybrid Kubernetes cluster (Edge + Cloud). Ensure you have `kubectl` configured to point to your cluster.

### 2. Developing the Frontend
The frontend is a Vite-powered React application that integrates Flutter assets.

```bash
cd frontend
npm install
npm run dev
```
The UI will be available at `http://localhost:5173`.

### 3. Running the Orchestrator (The Mayor)
The backend is written in Go. It coordinates the agent swarm and manages the durable event log.

```bash
cd orchestrator/the-mayor
go run main.go
```

---

## 🛠️ The Developer Workflow (The Golden Path)

### The Build Pipeline (Tekton)
We don't manually push images. We use Tekton pipelines for a hardened delivery path.

1. **Commit Changes:** Push your code to the git remote.
2. **Trigger Pipeline:** The `frontend-build-run` or `orchestrator-pipeline-run` is automatically triggered.
3. **Automated Validation:**
   - Go backend: Runs unit tests $\rightarrow$ Trivy security scan $\rightarrow$ Static binary build.
   - Frontend: Flutter build $\rightarrow$ Vite production build.
4. **Rolling Update:** Images are pushed to the local registry and rolled out via K3s.

### Testing the Agent Sandbox
To test a new "Polecat" actor behavior:
1. Define the actor's logic in the `ax-backend`.
2. Use the **Visual Cockpit** to trigger a `CreateWorkspace` tool call.
3. Monitor the **Durable Event Log** to see the state transitions.
4. Verify the sandbox boundary by attempting a restricted syscall (it should be blocked by `gVisor`).

---

## 📚 Troubleshooting & FAQ

**Q: Why is my UI not updating in real-time?**
Check if the AX MCP Server is healthy. The UI relies on an SSE stream; if the MCP server is down, the UI falls back to a static state.

**Q: How do I add a new node to the cluster?**
Run the `setup-gvisor-node.sh` script on the new node to install the `runsc` runtime and join the Tailscale mesh.

**Q: Where are the agent snapshots stored?**
Substrate uses local path volume-claims on the worker nodes for sub-millisecond teleportation.
