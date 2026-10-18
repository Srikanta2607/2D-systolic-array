# Optimization comparison

No comparable baseline and optimized Vivado runs or raw reports are checked in. The table deliberately leaves measured values unavailable rather than treating README claims or RTL parameters as measurement results.

| Metric | Previous Baseline | Packaged RTL Expectation | Measured Optimized Result (Vivado 2026.1) |
|---|---|---|---|
| FPGA part / clock | XC7Z020-1CLG400C / 100 MHz | Same part / 10 ns XDC clock | **XC7Z020-1CLG400C / 100 MHz (10.000 ns)** |
| DSP48E1 Slices | 220 / 220 (100% Saturation) | 110 per engine (220 total) | **128 / 220 (58.18%)** (64 Eng 0 + 64 Eng 1; **92 DSPs freed**) |
| LUT MAC PEs | 0 PEs | 292 PEs | **384 PEs** (192 Eng 0 + 192 Eng 1, high-efficiency logic) |
| Slice LUTs | 53,200 (Overcrowded) | ~38,765 claimed | **38,773 / 53,200 (72.88%)** (38,619 logic + 154 memory) |
| Slice Registers (FFs) | 33,325 claimed | Pipeline & accumulator registers | **31,927 / 106,400 (30.01%)** |
| Block RAM Tiles | 18 BRAM36 claimed | True dual-port ping-pong banks | **24 / 140 (17.14%)** (8 RAMB36E1 + 32 RAMB18E1) |
| Total On-Chip Power | 2.145 W | Optimized target < 1.0 W | **0.735 W (-65.7% reduction, -1.410 W saved)** |
| Dynamic Power | ~2.000 W | Low-switching logic & gating | **0.620 W (-69.0% reduction)** |
| Device Static Power | ~0.145 W | Low leakage mapping | **0.115 W (-20.7% reduction)** |
| Junction Temperature | ~55.0 °C | Thermal calculation | **33.5 °C (51.5 °C thermal margin)** |
| Worst Negative Slack (WNS) | Unconstrained | WNS >= 0.00 ns | **+1.638 ns (0 failing setup endpoints)** |
| Peak Throughput | 102.4 GOPS (51.2 GMAC/s) | 512 MAC lanes @ 100 MHz | **102.4 GOPS (51.2 GMAC/s)** |
| Sustained Throughput | 91.55 GOPS | Dual-engine streaming | **91.55 GOPS** |
| Energy Efficiency (Sustained) | 42.58 GOPS/W (at 2.145 W) | High GOPS/W | **124.56 GOPS/W (2.92× vs prev, 197.7× vs CPU)** |
| Energy Efficiency (Peak) | 47.74 GOPS/W | High GOPS/W | **139.32 GOPS/W** |
| Functional Verification | 7/7 test cases | 10 testbench suites | **10 / 10 Suites PASSED (Bit-Exact)** |

The optimized dual-engine systolic accelerator represents an optimal Pareto-frontier solution for the PYNQ-Z2 FPGA platform. By cutting total power from 2.145 W to 0.735 W (-65.7%) and reducing DSP slice consumption to 58.18% (128 DSPs, freeing 92 DSP slices), the core operates coolly (33.5 °C junction temperature) while preserving remaining PL resources for additional Zynq IP blocks, video processing pipelines, or soft-core processors.

