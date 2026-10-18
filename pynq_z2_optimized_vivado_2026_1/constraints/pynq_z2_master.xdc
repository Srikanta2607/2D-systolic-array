# ============================================================================
# PYNQ-Z2 Systolic Array Accelerator – Master Constraint File (Vivado 2026.1)
# Board   : PYNQ-Z2  (XC7Z020-1CLG400C)
# Clock   : 100 MHz via Zynq PS FCLK_CLK0 (10 ns period)
# ============================================================================

# -----------------------------------------------------------------------------
# Primary clock: 100 MHz core clock driven from Zynq PS FCLK
# The 'clk' port of accel_top_wrapper is connected to FCLK_CLK0 in block design.
# -----------------------------------------------------------------------------
create_clock -period 10.000 -name core_clk [get_ports clk]

# -----------------------------------------------------------------------------
# I/O timing budgets (OOC: 1 ns at each port boundary)
# These are relaxed since interfaces connect to PS/DMA in block design.
# -----------------------------------------------------------------------------
set_input_delay  -clock core_clk -max 1.000 \
    [get_ports -filter {DIRECTION == IN  && NAME != clk} *]
set_input_delay  -clock core_clk -min 0.000 \
    [get_ports -filter {DIRECTION == IN  && NAME != clk} *]
set_output_delay -clock core_clk -max 1.000 \
    [get_ports -filter {DIRECTION == OUT} *]
set_output_delay -clock core_clk -min 0.000 \
    [get_ports -filter {DIRECTION == OUT} *]

# Relax artificial hold checks on OOC boundary ports
# (In the full Zynq system, AXI/DMA ports connect synchronously on the same FCLK clock net)
set_false_path -hold -from [get_ports -filter {DIRECTION == IN && NAME != clk} *]
set_false_path -hold -to [get_ports -filter {DIRECTION == OUT} *]


# -----------------------------------------------------------------------------
# Power Optimization Directives
# -----------------------------------------------------------------------------
# Clock buffer is automatically inserted by Vivado for clk

# -----------------------------------------------------------------------------
# DSP48E1 Placement: Keep engine 0 and engine 1 DSPs in separate clock regions
# for better routing and lower interconnect power.
# Zynq XC7Z020 clock regions: X0Y0-X1Y0 (bottom), X0Y1-X1Y1 (top)
# Engine 0 DSPs → lower half, Engine 1 DSPs → upper half
# -----------------------------------------------------------------------------
# (Uncomment and adjust if Pblock placement is desired for power reduction)
# create_pblock pblock_engine0
# add_cells_to_pblock pblock_engine0 [get_cells u_dual_top/u_compute_core/u_systolic_0/*]
# resize_pblock pblock_engine0 -add CLOCKREGION_X0Y0:CLOCKREGION_X1Y0
#
# create_pblock pblock_engine1
# add_cells_to_pblock pblock_engine1 [get_cells u_dual_top/u_compute_core/u_systolic_1/*]
# resize_pblock pblock_engine1 -add CLOCKREGION_X0Y1:CLOCKREGION_X1Y1

# -----------------------------------------------------------------------------
# False paths: interrupt is a slowly-changing level signal
# -----------------------------------------------------------------------------
set_false_path -from [get_ports clk] -to [get_ports interrupt] -quiet
set_false_path -to [get_ports interrupt] -quiet
