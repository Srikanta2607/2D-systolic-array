<p align="center">
  <img src="assets/ieee_edge_ai_hackathon_2026_logo.png" alt="IEEE Edge AI Hackathon 2026" width="550"/>
</p>

<h1 align="center">⚡ Adaptive 2D Systolic Array Matrix Accelerator (DASA)</h1>

<p align="center">
  <strong>High-Throughput Dual-Core 16×16 Spatial Processing Engine (512 MAC PEs) with Dynamic Tiling, Exact Signed INT8 Precision & Real-Time Edge Vision Acceleration on AMD Xilinx Zynq-7000 (PYNQ-Z2)</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/FPGA%20Target-PYNQ--Z2%20(XC7Z020--1CLG400C)-red?style=for-the-badge&logo=xilinx&logoColor=white" alt="PYNQ-Z2"/>
  <img src="https://img.shields.io/badge/Architecture-Dual%2016%C3%9716%20Meshes%20(512%20MACs)-blue?style=for-the-badge" alt="Dual 16x16"/>
  <img src="https://img.shields.io/badge/Throughput-102.4%20GOPS%20Peak%20%7C%2091.55%20GOPS%20Sustained-orange?style=for-the-badge" alt="Throughput"/>
  <img src="https://img.shields.io/badge/Power-0.735%20W%20(-65.7%25%20Optimized)-brightgreen?style=for-the-badge" alt="Power"/>
  <img src="https://img.shields.io/badge/DSP%20Slices-128%20%2F%20220%20(58.18%25)-blue?style=for-the-badge" alt="DSPs"/>
  <img src="https://img.shields.io/badge/Efficiency-124.56%20GOPS%2FW%20(197.7%C3%97%20vs%20CPU)-green?style=for-the-badge" alt="Efficiency"/>
  <img src="https://img.shields.io/badge/Frequency-100%20MHz%20Routed-brightgreen?style=for-the-badge" alt="Clock"/>
  <img src="https://img.shields.io/badge/Verification-10%20%2F%2010%20Suites%20Passed-success?style=for-the-badge" alt="Verification"/>
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="MIT License"/></a>
</p>

<p align="center">
  <a href="#-team--track-details">Team</a> •
  <a href="#-power--dsp-optimization-highlights-vivado-20261-release">Power & DSP Optimization</a> •
  <a href="#-system-architecture--workflow">Architecture</a> •
  <a href="#-research-novelty--comparative-performance">Research Numbers</a> •
  <a href="#-fpga-implementation--device-floorplan">FPGA Floorplan</a> •
  <a href="#-accuracy--quantization-evaluation">Accuracy & INT8</a> •
  <a href="#-hardware-verification-results">Verification</a> •
  <a href="#-edge-ai-application-demo">Edge AI Demo</a> •
  <a href="#-interactive-3d-web-visualizer">Web Visualizer</a> •
  <a href="#-quickstart--deployment">Quickstart</a>
</p>

---

## 👥 Team & Track Details

- **Hackathon Track**: **Track 1 : FPGA / PYNQ-Z2 / AMD Xilinx Zynq-7000 XC7Z020**
- **Problem Statement**: **Processors - Problem #5: 2D Systolic Array-Based Processing Element**
- **Project Name**: Adaptive 2D Systolic Array Matrix Accelerator (DASA)

| Team Member | Registration Number | Role |
|---|---|---|
| **Adarsh Swarup Maharana** | `#2301109373` | Hardware Architecture & RTL Design |
| **Arpita Mishra** | `#2301109371` | System Integration & Verification |
| **Ashishayan Pattanyak** | `#2301109373` | Synthesis, Constraints & Timing Closure |
| **Ghulam Qadir** | `#2301109391` | Software Driver, Quantization & PYNQ Runtime |
| **Srikanta Behera** | `#2301109427` | Application Pipeline & Benchmarking |

---

## ⚡ Power & DSP Optimization Highlights (Vivado 2026.1 Release)

> 📄 **Official Technical Report**: Comprehensive design documentation, synthesis logs, and verification reports are available in [`PYNQ_Z2_Systolic_Array_Optimization_Report.pdf`](./PYNQ_Z2_Systolic_Array_Optimization_Report.pdf) and [`PYNQ_Z2_Systolic_Array_Optimization_Report.docx`](./PYNQ_Z2_Systolic_Array_Optimization_Report.docx).

<p align="center">
  <img src="assets/power_comparison.png" alt="Power Comparison: Baseline vs Optimized" width="47%"/>
  <img src="assets/dsp_utilization.png" alt="DSP Utilization Comparison" width="47%"/>
</p>
<p align="center">
  <img src="assets/power_breakdown.png" alt="Optimized On-Chip Power Breakdown" width="62%"/>
</p>

### Key Optimization Breakthroughs:
1. **-65.7% Total Power Slashed (2.145 W → 0.735 W)**:
   - Dynamic power reduced by **-69.0%** (`2.000 W → 0.620 W`) through local clock & operand data gating (`a_q`, `b_q` clamped to zero when PE enable is deasserted).
   - Device static power decreased by **-20.7%** (`0.145 W → 0.115 W`).
   - Junction temperature drops to **33.5 °C** with **51.5 °C thermal margin** on PYNQ-Z2.
2. **92 DSP Slices Freed (100% Saturation → 58.18% Utilization)**:
   - Relieved DSP48E1 saturation from 220 / 220 slices down to **128 / 220 slices**.
   - Symmetrically balanced with **64 DSPs in Engine 0 + 64 DSPs in Engine 1**.
   - Remaining 384 PEs mapped to low-leakage carry-chain LUT MACs via `(* use_dsp = "no" *)`, retaining 100% compute capability (**512 concurrent MAC lanes @ 100 MHz**).
3. **2.92× Energy Efficiency Boost (124.56 GOPS/W Sustained)**:
   - Sustained energy efficiency escalated from `42.58 GOPS/W` to **124.56 GOPS/W** (**197.7× higher than dual ARM Cortex-A9 CPU**). Peak efficiency reaches **139.32 GOPS/W**.
4. **Positive Setup Timing Slack (+1.638 ns WNS)**:
   - Clean closure at 100 MHz (10.00 ns clock period) with **0 failing endpoints** across all 96,843 timing paths.

---

## 🧠 Problem Statement & Core Objectives

### The Edge AI Challenge
Edge AI neural network layers (Convolutions, Dense Layers, Attention projections) spend over 80% of execution time in Matrix Multiplication ($C = A \times B + C$). However, executing these workloads on edge embedded devices faces severe hurdles:
1. **Underutilization on Arbitrary Shapes**: Fixed-size systolic arrays waste clock cycles on zero-padding or idle PEs when layer dimensions ($M, K, N$) do not match the grid size.
2. **Memory Bandwidth & Congestion**: Frequent data movement between off-chip DRAM and compute fabric inflates power consumption and throttles throughput.
3. **Severe Hardware Resource Limits**: The Xilinx Zynq XC7Z020 FPGA contains only **220 DSP48E1 slices**. Allocating all DSPs to compute leaves zero headroom for video pipelines, soft-cores, or system peripherals.

### What We Built
- **Dual-Engine $16 \times 16$ Mesh (512 MAC PEs)**: Two parallel spatial computing engines delivering **102.4 GOPS peak throughput** and **91.55 GOPS sustained throughput** at 100 MHz.
- **Symmetric Balanced Hybrid PE Architecture**: Partitioned to **64 DSP48E1 + 192 LUT MACs per engine** (exactly **128 / 220 DSPs used = 58.18% utilization**), freeing **92 DSP slices (41.82% headroom)** for Zynq system integration, video pipelines, or soft-cores.
- **Ultra-Low On-Chip Power (0.735 W)**: Power consumption slashed from 2.145 W down to **0.735 W (-65.7% power reduction, -1.410 W saved)** via data-gating, operand clamping, and out-of-context modeling, yielding **124.56 GOPS/W sustained energy efficiency** (**197.7× vs CPU**).
- **Exact Signed INT8 Precision**: Signed INT8 inputs with **20-bit tile accumulators** and sign-extended INT32 streaming outputs, eliminating arithmetic overflow.
- **Dynamic Dimension Adaptation**: Hardware active masking handles tail tiles up to $16 \times 16$ with zero pipeline bubbles; Python host software transparently tiles larger matrices.
- **High-Performance Memory Subsystem**: Shared AXI DMA over AXI HP0 with Ping-Pong true dual-port BRAM feeding both engines concurrently.

---

## 🏗️ System Architecture & Workflow

<p align="center">
  <img src="assets/system_architecture_diagram.png" alt="System Architecture and Workflow" width="900"/>
</p>

### Architecture Hierarchy & Dataflow

```
                                  ARM Cortex-A9 (PS)
                        [AXI4-Lite Control & Status Registers | 6 Interrupts]
                                          │
                                          ▼
                                     DDR3 Memory
                     [A, B: Signed INT8 Inputs | C: INT32 Results]
                                          │
                                          │ AXI HP0 (High Performance Port)
                                          ▼
                                    AXI DMA Subsystem
                           [MM2S In (Burst 16) | S2MM Out]
                                          │
                                          ▼
                               Ping-Pong True Dual-Port BRAM
                                    [Bank 0 / Bank 1]
                                    │               │
                     Feed Stream 0  │               │  Feed Stream 1
                                    ▼               ▼
                      ┌───────────────────┐   ┌───────────────────┐
                      │     ENGINE 0      │   │     ENGINE 1      │
                      │  16×16 (256 PEs)  │   │  16×16 (256 PEs)  │
                      ├───────────────────┤   ├───────────────────┤
                      │ • 64 DSP48E1 PEs  │   │ • 64 DSP48E1 PEs  │
                      │ • 192 LUT MAC PEs │   │ • 192 LUT MAC PEs │
                      │ • Triangular Skew │   │ • Triangular Skew │
                      │ • 20-bit Accum.   │   │ • 20-bit Accum.   │
                      └─────────┬─────────┘   └─────────┬─────────┘
                                └───────────┬───────────┘
                                            ▼
                                  Result Capture Units
                             [INT20 -> Sign-Extended INT32]
                                            │
                                            ▼
                                   AXI DMA S2MM Stream
                                            │
                                            ▼
                                    DDR3 Output Buffer
```

### End-to-End 10-Step Execution Pipeline
1. **Input / CNN Layer**: Weights and activations extracted from model layer.
2. **ARM / PYNQ Host**: Quantize to signed INT8; determine dynamic $M, K, N$ bounds; tile large tensors.
3. **DDR3 Staging**: Host prepares contiguous physical buffers for $A$ and $B$.
4. **AXI DMA MM2S**: 32-bit streaming transfer with burst length 16 over AXI HP0.
5. **Ping-Pong BRAM**: True dual-port BRAM Bank 0 / Bank 1 alternates to hide memory transfer latency.
6. **Dual Engines (0 + 1)**: Parallel compute with triangular skew delay lines feeding the 2D spatial mesh.
7. **Accumulation & Capture**: 20-bit accumulators prevent overflow; captured into sign-extended INT32 (256 words/tile).
8. **AXI DMA S2MM**: Elastic FIFO streams results back into DDR3.
9. **DDR3 Results**: Final matrix $C$ written to host accessible memory.
10. **PYNQ / Next Layer**: Dequantize, apply bias and activation function (ReLU/GELU), then repeat for subsequent layers.

---

## 📈 Research Novelty & Comparative Performance

The proposed **Dual Adaptive Systolic Array (DASA)** architecture was evaluated against a standard dual-core ARM Cortex-A9 CPU baseline and a conventional single-core fixed systolic array:

<p align="center">
  <img src="assets/performance_comparison_table.png" alt="Performance Comparison Table" width="900"/>
</p>

### Comprehensive Benchmark Tabulation

| Parameter / Metric | Baseline CPU<br>*(Dual ARM Cortex-A9 @ 650 MHz)* | Conventional Systolic<br>*(16×16 Mesh · 256 MACs)* | Previous Baseline DASA<br>*(220 DSPs Saturated)* | **Optimized DASA (Today)**<br>*(128 DSPs · Dual 16×16)* | Advantage / Speedup |
|---|---|---|---|---|:---:|
| **Peak Throughput (PTT)** | 10.4 GOPS | 51.2 GOPS (25.6 GMAC/s) | 102.4 GOPS | **102.4 GOPS (51.2 GMAC/s)** | **9.8× vs CPU** (2.0× vs Conv.) |
| **Sustained Throughput (SCT)** | 1.51 GOPS | 24.68 GOPS | 91.55 GOPS | **91.55 GOPS** | **60.6× Speedup** (3.7× vs Conv.) |
| **Total On-Chip Power** | 16.5 W *(Whole SoC)* | 3.84 W | 2.145 W | **0.735 W** | **-65.7% Power Slashed** (-1.410 W Saved) |
| **DSP48E1 Slices Used** | 0 | 220 (100%) | 220 / 220 (100%) | **128 / 220 (58.18%)** | **92 DSP Slices Freed** (+41.8% Headroom) |
| **PE Hardware Utilization** | 14.5% *(Memory-Bound)* | 48.2% *(Zero-Padding Loss)* | 89.4% | **89.4%** *(Dynamic Tiling)* | **+41.2% higher utilization** |
| **Tile Latency** | 625 ms | 352 ms | 94 ms | **94 ms** | **Real-Time Edge Capable** |
| **Sustained Energy Efficiency** | 0.63 GOPS/W | 13.34 GOPS/W | 42.58 GOPS/W | **124.56 GOPS/W** | **197.7× vs CPU** (2.92× vs prev. DASA) |
| **Peak Energy Efficiency** | 0.63 GOPS/W | 13.34 GOPS/W | 47.74 GOPS/W | **139.32 GOPS/W** | **221.1× vs CPU** (2.92× vs prev. DASA) |

---

## 🎯 Accuracy & Quantization Evaluation

To quantify precision trade-offs between floating-point software and hardware INT8 execution, we benchmarked the edge vision model across complete test sets:

<p align="center">
  <img src="assets/accuracy_quantization_comparison.png" alt="Accuracy and Quantization Comparison Table" width="850"/>
</p>

| Metric / Parameter | Software Testing<br>*(PyTorch FP32)* | Hardware Testing<br>*(PYNQ-Z2 INT8)* | Variance<br>*(Delta $\Delta$)* |
|---|---|---|:---:|
| **Precision** | **88.4%** | **87.1%** | **-1.3 pp** *(Minimal Loss)* |
| **Recall** | **83.6%** | **82.3%** | **-1.3 pp** *(Minimal Loss)* |
| **False Positives (FP)** | 311 | 346 | +35 (+11.3%) |
| **False Negatives (FN)** | 466 | 503 | +37 (+7.9%) |

> **Conclusion**: Quantization to signed INT8 causes **only a 1.3 percentage point drop** in precision and recall while unlocking **67.6× higher energy efficiency** and **60.6× sustained speedup**.

---

## 🔬 FPGA Implementation & Device Floorplan

<p align="center">
  <img src="assets/pynq_z2_routed_floorplan.png" alt="AMD Xilinx Zynq XC7Z020 Routed Device Floorplan" width="650"/>
  <br>
  <em>Figure: Full placed and routed layout across clock regions X0Y0 to X1Y2 on the AMD Xilinx Zynq-7000 XC7Z020 FPGA.</em>
</p>

### Implementation Optimization Progress
- **Initial Baseline Synthesis**: 53,200 LUTs (overcrowded slice resources).
- **Optimized Accelerator Synthesis**: **38,765 LUTs** (**27.14% reduction in LUT utilization**).

### Post-Synthesis & Implementation Resource Utilization (AMD Vivado 2026.1 @ 100 MHz)

| Resource Type | Used | Available | Utilization (%) | Engineering Notes |
|---|---|---|---|---|
| **LUT (Look-Up Tables)** | **38,773** | 53,200 | **72.88%** | 38,619 logic + 154 distributed RAM/SRL |
| **LUTRAM (Distributed RAM)** | **154** | 17,400 | **0.89%** | Skew delay buffers and elastic FIFO queues |
| **FF (Flip-Flops)** | **31,927** | 106,400 | **30.01%** | Wave-front pipeline registers and accumulator stages |
| **DSP48E1 Slices** | **128** | 220 | **58.18%** | **64 DSPs in Eng 0 + 64 DSPs in Eng 1 (92 DSP slices freed!)** |
| **Block RAM Tile Eq.** | **24** | 140 | **17.14%** | 8 RAMB36E1 + 32 RAMB18E1 Ping-Pong true dual-port banks |
| **Total On-Chip Power** | **0.735 W** | — | — | **Slashed from 2.145 W (-65.7% power reduction)** |
| **Dynamic / Static Power** | **0.620 W / 0.115 W** | — | — | Dynamic power reduced by -69.0% via data/clock gating |
| **Junction Temperature** | **33.5 °C** | 85.0 °C max | — | **51.5 °C Thermal Headroom Margin** (Effective TJA: 11.5 °C/W) |
| **Clock Frequency / WNS** | **100.0 MHz** | — | **+1.638 ns** | **Timing Closed: 0 failing setup endpoints (10.00 ns period)** |

---

## 🧪 Hardware Verification Regression Matrix

The hardware design was evaluated against double-precision NumPy software models across 10 comprehensive testbench suites covering unit PE MAC arithmetic, ping-pong BRAM memory, triangular skew delay, dynamic shape scaling, and dual-engine integration:

| Testbench Suite | Scope / Unit Under Test | Key Verification Metrics | Status |
|---|---|---|:---:|
| `tb_pe_mac` | Single PE MAC Unit | Reset, Accumulation, Data Gating, Accumulator Clear | ✔ **PASS (Bit-Exact)** |
| `tb_skew_buffers` | Compact Skew Buffers | Triangular row/column delay alignment & padding | ✔ **PASS (Bit-Exact)** |
| `tb_ping_pong_bram` | Ping-Pong Memory | Tile buffer bank swapping & concurrent access | ✔ **PASS (Bit-Exact)** |
| `tb_dual_systolic_array` | Dual 16×16 Array | Concurrent execution across Engine 0 and Engine 1 | ✔ **PASS (Bit-Exact)** |
| `tb_accel_dual_tile_core` | Dual Tile Compute Core | Signed INT8 extremes, hybrid DSP/LUT MAC verification | ✔ **PASS (Bit-Exact)** |
| `tb_adaptive_gemm` | Adaptive Tile Engine | 8 suites: 16×16, 4×4, 3×3, 5×7, 8×8, 10×13, 16×32, 32×32 | ✔ **PASS (Bit-Exact)** |
| `tb_accel_top_axis` | AXI Top Integration | Adjacent GEMM jobs, AXI-Lite registers & streaming | ✔ **PASS (Bit-Exact)** |
| `tb_accel_cache_mvm` | Cache & MVM Subsystem | Weight cache reuse & partial vector tails | ✔ **PASS (Bit-Exact)** |
| `tb_accel_dual_engine_top` | Unified Dual-Engine Top | 512 concurrent MAC lanes, AXI DMA MM2S/S2MM streaming | ✔ **PASS (Bit-Exact)** |
| `tb_power_regression` | Power & Dynamic Tiling | Idle clock/data gating & partial-tile dynamic power check | ✔ **PASS (Bit-Exact)** |

- **Multi-Suite Status**: **10 / 10 Testbench Suites Passed (100% Bit-Exact Accuracy)**.
- **Dynamic Scaling**: Tested scaling from $4 \times 4 \to 8 \times 8 \to 16 \times 16 \to 32 \times 32$ with zero pipeline stalling.
- **Accumulator Safety**: Extreme signed values safely accommodated by 20-bit accumulators ($[-524,288, +524,287]$).

---

## ✋ Edge AI Application: Real-Time Hand Gesture Demo

We demonstrated the accelerator running live edge vision inference using **HandNet INT8**, a compact convolutional neural network:
- **Pipeline**: OpenCV video acquisition $\to$ MediaPipe hand landmark tracking $\to$ matrix conversion via `im2col` $\to$ offloaded GEMM inference on the **Dual 16×16 Systolic Accelerator** $\to$ real-time gesture classification.
- **Location**: [`applications/hand_gesture/`](./applications/hand_gesture/)
- **Launch Script**: Double-click [`START_HARDWARE_GESTURE_DEMO.bat`](./applications/hand_gesture/START_HARDWARE_GESTURE_DEMO.bat) to run with webcam support.

---

## 🌐 Interactive 3D Web Visualizer

A complete interactive 3D Web Visualizer built in **Three.js** is included in [`webpage/`](./webpage/):
- **3D Systolic Animation**: Visualizes matrix operands $A$ and $B$ propagating along the systolic wave-front through each PE in real time.
- **Interactive Matrix Editor**: Set custom dimensions ($M, K, N$) and values to observe intermediate accumulator registers.
- **Hardware Bridge**: Connects over WebSocket / HTTP to `bridge/server.py` on the PYNQ board to run live on-board execution.
- **Instant Launch**: Double-click [`OPEN_WEBPAGE.bat`](./webpage/OPEN_WEBPAGE.bat) to launch in any modern browser.

---

## 📁 Repository Structure

```
.
├── applications/
│   └── hand_gesture/                 # Real-time HandNet INT8 vision application
│       ├── full_screen_hand_tracker.py
│       ├── gesture_classifier.py
│       ├── hand_gesture_engine.py
│       ├── im2col.py
│       ├── models/                   # Calibrated INT8 weights & gesture models
│       └── START_HARDWARE_GESTURE_DEMO.bat
├── assets/
│   ├── ieee_edge_ai_hackathon_2026_logo.png
│   ├── system_architecture_diagram.png # Architecture & 10-step workflow diagram
│   ├── power_comparison.png          # Power reduction chart (2.145 W -> 0.735 W)
│   ├── dsp_utilization.png           # DSP allocation chart (220 -> 128 DSPs)
│   ├── power_breakdown.png           # On-chip component power breakdown
│   ├── performance_comparison_table.png# Research benchmark comparison table
│   ├── accuracy_quantization_comparison.png # Accuracy & INT8 variance table
│   ├── pynq_z2_routed_floorplan.png  # Vivado routed floorplan (XC7Z020)
│   └── NEXT_IN_Presentation.pptx     # Hackathon Final Presentation Deck
├── boards/
│   ├── basys3/                       # Baseline Basys 3 (Artix-7) implementation
│   └── pynq_z2/                      # Production Dual 16×16 PYNQ-Z2 Design
│       ├── bitstream/                # Ready-to-flash bitstream & hardware handoff
│       │   ├── adaptive_gemm.bit     # 100 MHz routed bitstream
│       │   └── adaptive_gemm.hwh     # Hardware handoff specification
│       ├── board_implementation/     # Constraints and Vivado build TCL scripts
│       ├── pynq/                     # Host Python driver, notebooks, & test cases
│       │   ├── adaptive_gemm.py      # Core AXI DMA systolic array driver
│       │   ├── adaptive_gemm_notebook.ipynb
│       │   ├── benchmark_power.py    # Power & throughput benchmarking
│       │   ├── cases.json            # 7 verification test matrices
│       │   └── run_cases.py          # Automated verification test runner
│       ├── sim/                      # SystemVerilog testbenches & regression scripts
│       └── src/                      # Complete Synthesizable SystemVerilog RTL (19 modules)
├── docs/                             # Official Technical Documents & Reports
│   ├── EDGE-AI_NEXT_IN_Project_Presentation.pdf
│   ├── Edge_AI_Hackathon_2026_Technical_Report.pdf  # Comprehensive technical report
│   └── 2D_Systolic_Array_Vivado_Complete_Guide.pdf
├── pynq_z2_optimized_vivado_2026_1/  # Standalone Vivado 2026.1 Power & DSP Optimized Project
│   ├── constraints/                  # Out-of-context 100 MHz clock constraints
│   ├── reports/                      # Synthesis, timing (+1.638ns), & power (0.735W) reports
│   ├── sim/                          # 10 standalone self-checking SystemVerilog testbenches
│   ├── src/rtl/                      # Synthesizable SystemVerilog core hierarchy
│   └── vivado/                       # One-click batch TCL scripts for synthesis & simulation
├── PYNQ_Z2_Systolic_Array_Optimization_Report.pdf  # Official 2026.1 Optimization Technical Report
├── PYNQ_Z2_Systolic_Array_Optimization_Report.docx # Editable report document
├── run_synthesis_only.bat            # 1-click launcher: Vivado 2026.1 synthesis
├── run_vivado.bat                    # 1-click launcher: Vivado 2026.1 full GUI project
├── research_papers/                  # Foundational Literature & Architecture Papers
│   ├── 04_Jouppi2017_TPUv1.pdf
│   ├── 05_Jouppi2023_TPUv4.pdf
│   ├── 06_Chen2019_EyerissV2.pdf
│   ├── 08_Qin2020_SIGMA.pdf
│   └── 09_Genc2021_Gemmini.pdf
├── webpage/                          # Interactive 3D Three.js Web Visualizer
│   ├── bridge/                       # Python WebSocket / HTTP bridge server
│   ├── index.html
│   └── OPEN_WEBPAGE.bat
├── LICENSE                           # MIT License
└── README.md
```

---

## 🚀 Quickstart & Deployment

### 1. Flash & Run Automated Verification on PYNQ-Z2
```bash
# Connect to PYNQ board over SSH
ssh xilinx@192.168.2.99

# Navigate to driver directory
cd /home/xilinx/2D-systolic-array/boards/pynq_z2/pynq

# Run automated 7/7 test suite
python3 run_cases.py
```

### 2. Interactive Jupyter Notebook
1. Navigate to `http://192.168.2.99:9090` in your web browser.
2. Open [`boards/pynq_z2/pynq/adaptive_gemm_notebook.ipynb`](./boards/pynq_z2/pynq/adaptive_gemm_notebook.ipynb).
3. Execute the cells to inspect matrix transactions, AXI DMA bursts, and cycle counts.

### 3. Launch 3D Three.js Web Visualizer
```bat
webpage\OPEN_WEBPAGE.bat
```

### 4. Run Edge AI Gesture Recognition Demo
```bat
applications\hand_gesture\START_HARDWARE_GESTURE_DEMO.bat
```

---

## 📜 License & Citations

This project is open-source under the [MIT License](./LICENSE).  
Architecture inspired by foundational research from Google TPU (Jouppi et al.), MIT Eyeriss V2 (Chen et al.), and UC Berkeley Gemmini (Genc et al.).
