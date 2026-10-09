# Gaming Readiness Score Specification

The **Gaming Readiness Score** is a standardized metric (scaled from **0 to 100**) calculated dynamically by `SystemDetector.calculateReadinessScore(...)` in `MacOSGamingCore`. It quantifies whether a Mac's hardware architecture, unified memory configuration, operating system version, and software environment are suitable for running Windows titles smoothly via macOS compatibility layers (Wine-CX, DXMT, DXVK, and Rosetta 2).

---

## 1. Scoring Formula & Breakdown

The score evaluates five key pillars:

| Category | Condition / Threshold | Points Awarded | Technical Rationale |
| :--- | :--- | :---: | :--- |
| **1. Processor Architecture** | **Apple Silicon (M1, M2, M3, M4)** | **+30** | Native ARM64 execution, high-bandwidth Unified Memory Architecture, Metal 3/3.1 GPU feature sets. |
| | Intel x86_64 | **0** | Legacy architecture; lacks unified CPU/GPU bandwidth and modern Metal 3 GPU features. |
| **2. Unified Memory (RAM)** | **$\ge$ 32 GB RAM** | **+25** | Enthusiast tier: ample headroom for high-res 4K textures, Wine translation buffers, zero swap activity. |
| | **16 GB to < 32 GB RAM** | **+20** | **Recommended Baseline:** Sufficient unified memory for modern 3D games, OS background tasks, and translation runtime. |
| | **8 GB to < 16 GB RAM** | **-10 (Penalty)** | **Constrained Tier:** Shared UMA causes memory starvation between CPU and GPU; heavy SSD swapping and micro-stuttering. |
| | **< 8 GB RAM** | **-20 (Penalty)** | **Inadequate Tier:** Insufficient memory for basic OS overhead and translation runtime combined. |
| **3. macOS Version & AVX2** | **macOS $\ge$ 15 (Sequoia, Tahoe, etc.)** | **+20** | Full Rosetta 2 support with AVX and AVX2 instruction set emulation (`ROSETTA_ADVERTISE_AVX=1`). |
| | macOS < 15 (Sonoma, Ventura, etc.) | **+5** | Lacks AVX2 translation in Rosetta 2; games compiling AVX instructions crash with `STATUS_ILLEGAL_INSTRUCTION`. |
| **4. Rosetta 2 Runtime** | **Installed & Active** | **+15** | Translates x86_64 Windows executables and Wine binaries to ARM64 instructions. |
| | Not Installed | **0** | System cannot execute x86_64 binaries (`softwareupdate --install-rosetta` required). |
| **5. Free APFS Storage Space**| **$\ge$ 50 GB free** | **+10** | Sufficient room for wine prefixes, game installations, shader caches, and APFS snapshots. |
| | **25 GB to < 50 GB free** | **+5** | Adequate space for lightweight game installations and runtime prefixes. |
| | < 25 GB free | **0** | Critical storage constraint; risk of prefix creation failure or disk exhaustion. |

$$\text{Final Score} = \min(100, \max(0, \text{Total Points}))$$

---

## 2. Technical Justification for the RAM < 16 GB Penalty

Apple Silicon utilizes a **Unified Memory Architecture (UMA)** where the CPU, Metal GPU, and Neural Engine share a single contiguous physical memory pool. Unlike traditional PCs with dedicated VRAM (e.g., 8 GB GPU VRAM + 16 GB System RAM), a Mac with 8 GB unified memory must fit all workloads within that single 8 GB budget:

1. **Host Operating System Overhead:** macOS and WindowServer typically require **3.0 to 4.0 GB** of RAM under normal desktop operation.
2. **Translation Layer Overhead:** Wine-CX runtime, Rosetta 2 JIT translation caches, and Direct3D-to-Metal translation pipelines (DXMT / DXVK) require **1.0 to 2.0 GB** of operational memory.
3. **GPU VRAM Allocation:** Modern 3D titles require at least **4.0 to 6.0 GB** of dedicated texture and buffer memory.
4. **The 8 GB Bottleneck:** On an 8 GB Mac, available memory is immediately exhausted when launching a 3D title. The Darwin kernel is forced into aggressive compression and SSD swapping, resulting in:
   - Severe frame time variance and perceptible micro-stuttering.
   - Texture streaming pop-in and resolution degradation.
   - Out-of-memory terminations (`EXC_RESOURCE` or abort exceptions).

Consequently, **RAM configurations below 16 GB are penalised with -10 points** (and < 8 GB with **-20 points**), establishing **16 GB as the true baseline for modern Mac gaming**.

---

## 3. Score Tiers & Readiness Levels

| Score Range | Classification | User Guidance |
| :---: | :--- | :--- |
| **90 – 100** | **Optimal Readiness** | Machine is fully equipped for modern gaming across DX11/DX12 titles via Wine-CX and DXMT. High texture presets supported. |
| **70 – 89** | **Good Readiness** | System runs most compatible titles smoothly. May require medium texture presets or moderate resolution scaling. |
| **50 – 69** | **Constrained Readiness** | Experiencing memory or OS bottlenecks (e.g., 8 GB RAM or pre-AVX2 macOS). Recommended for lightweight, indie, or older DX9/DX11 titles. |
| **0 – 49** | **Incompatible / Not Recommended** | Crucial components missing (Intel CPU, missing Rosetta 2, or insufficient RAM/storage). Follow CLI doctor recommendations. |
