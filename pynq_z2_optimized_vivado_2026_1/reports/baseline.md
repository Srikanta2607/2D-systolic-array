# Baseline inspection

## Scope and source

Inspected the repository's `boards/pynq_z2/src`, `boards/pynq_z2/sim`, board constraints, and Vivado Tcl flow. The actual accelerator top is `accel_dual_axi_top`; it instantiates two `accel_top` engines and uses the XC7Z020 part `xc7z020clg400-1` (PYNQ-Z2 XC7Z020-1CLG400C). The source package copies the full RTL and all ten SystemVerilog benches into its own `src/rtl` and `sim` directories.

The top is an AXI/AXI-Stream accelerator IP. Its `clk` port is the 100 MHz core clock. Board-level PS, DMA, external memory, and physical I/O are not in this top. The original OOC XDC constrains the clock at 10 ns and budgets 1 ns for input/output paths; it contains no package-pin locations. PYNQ-Z2 LED pin constraints apply to a separate demo top and therefore do not apply here.

## RTL findings

- Two independently controlled 16x16 systolic meshes are instantiated: 512 logical PEs total.
- Each mesh uses a row-major hybrid selection: 110 DSP-oriented PEs and 146 `use_dsp="no"` LUT-oriented PEs. This is a synthesis intent, not a verified post-synthesis count in this report.
- Inputs are signed 8-bit, full products are 16-bit signed, and the board accelerator's per-tile accumulator is 20-bit. K is bounded to a 16-element tile in the top-level configuration. The positive extreme is 16 × (-128 × -128) = 262,144, within signed 20-bit range.
- PE forwarding and accumulator state are reset synchronously active-low. Enable/ingress masking and zero-padded streams suppress inactive multiply inputs in integrated paths. The RTL already includes configurable DSP/LUT mapping and overflow tracking.
- Power-related RTL already masks inactive ingress operands to zero and updates accumulators only when enabled; it does not use fabric-generated clocks. No activity-annotated A/B power reports are present to quantify savings.
- The board wrapper exposes AXI-Lite and AXI-Stream ports; it needs a Zynq/AXI block design to be programmed as a PYNQ-Z2 system.

## Evidence gaps

The parent README states 38,765 LUTs, 33,325 FFs, 220 DSPs, 18 BRAM36 equivalents, 100 MHz timing closure, and several benchmark/power figures. No raw Vivado utilization, timing, or power report was found in the checked-in PYNQ-Z2 tree, so those values are recorded as unverified repository claims, not baseline measurements. The reported 2.145 W has no checked-in matching report/activity data establishing whether it is PL-only, whole-device, vectorless, or board-measured.

The PYNQ-Z2 XC7Z020 device has 220 DSP48E1 slices, 53,200 LUTs, 106,400 flip-flops and 140 36-Kb BRAM equivalents. Thus the stated 220-DSP target exactly consumes the DSP budget; the README's claimed LUT/FF values are below device totals but remain unverified without reports. The board uses the XC7Z020-1CLG400C according to AMD's [PYNQ-Z2 specification](https://www.amd.com/en/corporate/university-program/aup-boards/pynq-z2.html); the package part string is `xc7z020clg400-1`.

The existing Vivado project Tcl references `simulation/` while the checked-in testbenches are under `sim/`; the packaged Tcl uses the correct local path. No Vivado or standalone simulator executable was available on PATH in the environment used to prepare this package, so no synthesis, implementation, power estimate, or simulation is claimed as run here.
