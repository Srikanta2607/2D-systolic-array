# PYNQ-Z2 optimized systolic accelerator (Vivado 2026.1)

This is a standalone, relocatable Vivado project package for the repository's PYNQ-Z2 accelerator IP. It targets **XC7Z020-1CLG400C** (`xc7z020clg400-1`) and a 100 MHz `clk`. The Tcl flow targets Vivado 2026.1, matching your installed version. It preserves the original RTL in this folder and leaves the parent project untouched.

## What is included

- `src/rtl/`: the complete checked-in PYNQ-Z2 SystemVerilog hierarchy and wrapper.
- `sim/`: ten standalone self-checking SystemVerilog benches. The board-level power bench is excluded because it depends on generated PS simulation files not present in the source repository.
- `constraints/pynq_z2_master.xdc`: the original verified out-of-context clock and interface-delay constraints. This is an accelerator IP interface, not a board-pin top; no package pins are assigned.
- `vivado/`: project, simulation, synthesis, implementation, resource and power Tcl entry points.
- `reports/`: source-based baseline and comparison notes. Vivado output reports are generated here when Vivado is run.

## Open or regenerate on Windows

Open Vivado 2026.1's Tcl console, change to this folder, then run:

```tcl
source vivado/create_project.tcl
```

Alternatively, from a Vivado Command Prompt in this folder:

```bat
vivado -mode batch -source vivado\create_project.tcl
```

The generated project is in `vivado/build/`. The source and scripts use paths relative to this package, so the whole folder can be moved. Re-running `create_project.tcl` recreates that generated project directory.

## Run simulation, synthesis, and implementation

For the dual-engine regression, the testbench is `sim/tb_power_regression.sv`. Run only this bench from a Vivado 2026.1 command prompt in this folder:

```bat
vivado -mode batch -source vivado\run_power_regression.tcl
```

This compiles the packaged RTL and checks the 110-DSP-per-engine configuration. To run all ten standalone benches sequentially, use:

```bat
vivado -mode batch -source vivado\run_simulation.tcl
```

The script runs ten self-checking benches in XSIM and stops on a simulator fatal. Individual benches can also be selected in Vivado's Simulation Settings by setting the simulation top to their module name.

Generate reports with:

```bat
vivado -mode batch -source vivado\run_synthesis.tcl
vivado -mode batch -source vivado\run_implementation.tcl
```

Outputs appear under `reports/vivado_synth/` and `reports/vivado_impl/`. With an open project after a run, `source vivado/report_resources.tcl` and `source vivado/report_power.tcl` regenerate reports under `reports/vivado_manual/`.

The power script produces Vivado's **vectorless estimate**. Workload-annotated power requires a matching routed design and SAIF/VCD activity; the 2.145 W value in the original task is not established as comparable PL power by any raw report in this checkout. A vectorless estimate is not a board measurement.

## Architecture and numeric limits

The top, `accel_dual_axi_top`, instantiates two independently controlled 16x16 engines. Each mesh has 256 PEs; `MAC_IMPL("HYBRID")` assigns the first 110 row-major PEs to DSP arithmetic and the remaining 146 to LUT arithmetic. Total design target is 220 DSP MAC PEs and 292 LUT MAC PEs. This is the RTL's intended mapping; confirm the actual DSP/LUT counts in Vivado reports.

Operands are signed 8-bit. A full signed product is represented in 16 bits; the range is -16,384 through +16,384. For a single K tile of at most 16 products, the maximum positive magnitude is 262,144 and fits signed 20-bit accumulation (-524,288 to +524,287). The AXI adapter sign-extends results into 32-bit stream words. This bound applies per tile; software-level multi-tile accumulation behavior must follow the driver's contract.

The XC7Z020 has 220 DSP48E1 slices, 53,200 LUTs, 106,400 flip-flops, and 140 36-Kb BRAM equivalents. The nominal 110 + 110 partition uses all device DSPs, leaving no DSP margin. The parent README claims 38,765 LUTs and 33,325 FFs post-route, which would fit those device totals, but the raw reports are absent so the claim is not independently verified. The dual-engine target is therefore plausible from the published totals, but resource fit, timing closure and power are not confirmed by this package. If the target fails, adjust `DSP_PE_LIMIT` to 96, 80, or 64 in the design and re-run synthesis/implementation; each reduction trades DSPs for LUT multipliers and must be measured.

The RTL already includes power-aware behavior: ingress padding supplies zeros to inactive rows/columns, accumulator state only updates when enabled, and no fabric-generated clock is used. The forwarding registers can still toggle on padded data, and no same-condition power comparison is available to show how much this reduces switching.

## Board integration and programming

This project sets the AXI accelerator IP as top, so it is suitable for simulation and out-of-context synthesis/implementation. It is **not a complete PS/DMA board shell** and does not produce a PYNQ-loadable bitstream. For hardware, integrate this IP with the Zynq PS, AXI DMA/stream and address map in a Vivado block design, export the matching `.bit` and `.hwh`, then deploy both to PYNQ. Do not assign the IP's AXI interface signals directly to PYNQ-Z2 package pins. The repository's existing board flow can be used as integration reference; it is intentionally not referenced outside this self-contained folder.

See `reports/baseline.md`, `reports/optimization_comparison.md`, and `reports/verification.md` for what is known and what remains to be measured.
