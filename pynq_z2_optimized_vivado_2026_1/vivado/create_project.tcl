# ============================================================================
# create_project.tcl  - PYNQ-Z2 Systolic Array Accelerator (Power Optimized)
# Vivado 2026.1  |  Part: xc7z020clg400-1  |  Board: PYNQ-Z2
# Run with: vivado -mode batch -source vivado/create_project.tcl
# NOTE: Uses list_files instead of glob to handle paths with spaces.
# ============================================================================

# Resolve root path relative to this script (handles spaces correctly)
set script_dir [file dirname [file normalize [info script]]]
set root       [file normalize [file join $script_dir ..]]
set rtl_dir    [file join $root src rtl]
set sim_dir    [file join $root sim]
set xdc_file   [file join $root constraints pynq_z2_master.xdc]
set project_dir [file join $root vivado_build]

file mkdir $project_dir

# Create/overwrite the project
create_project pynq_z2_systolic_optimized \
    [file normalize $project_dir] \
    -part xc7z020clg400-1 -force

# Project settings
set_property target_language    Verilog [current_project]
set_property simulator_language Mixed   [current_project]
set_property default_lib        work    [current_project]

# -----------------------------------------------------------------------
# Add RTL source files one by one (avoids glob space issues)
# -----------------------------------------------------------------------
set rtl_files [concat \
    [glob -nocomplain -directory $rtl_dir *.sv] \
    [glob -nocomplain -directory $rtl_dir *.v]]

if {[llength $rtl_files] == 0} {
    error "No RTL files found in: $rtl_dir"
}

puts "Adding [llength $rtl_files] RTL files..."
foreach f $rtl_files {
    add_files -norecurse [list [file normalize $f]]
}

# Top module for synthesis: pure-Verilog wrapper (required for IP Integrator)
set_property top accel_top_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1

# -----------------------------------------------------------------------
# Add constraints
# -----------------------------------------------------------------------
if {![file exists $xdc_file]} {
    error "Missing constraints file: $xdc_file"
}
add_files -fileset constrs_1 -norecurse [list [file normalize $xdc_file]]

# -----------------------------------------------------------------------
# Add simulation testbenches
# -----------------------------------------------------------------------
set sim_files [glob -nocomplain -directory $sim_dir *.sv]
if {[llength $sim_files] > 0} {
    puts "Adding [llength $sim_files] simulation files..."
    foreach f $sim_files {
        add_files -fileset sim_1 -norecurse [list [file normalize $f]]
    }
    set_property top tb_dual_systolic_array [get_filesets sim_1]
    set_property xsim.simulate.runtime all  [get_filesets sim_1]
    update_compile_order -fileset sim_1
} else {
    puts "WARNING: No simulation testbenches found in: $sim_dir"
}

# -----------------------------------------------------------------------
# Power Optimization: Synthesis strategy (Out-of-Context IP block)
# -----------------------------------------------------------------------
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE PowerOptimized_high [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION on [get_runs synth_1]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

# -----------------------------------------------------------------------
# Power Optimization: Implementation strategy
# -----------------------------------------------------------------------
set_property STEPS.OPT_DESIGN.IS_ENABLED                  true [get_runs impl_1]
set_property STEPS.POWER_OPT_DESIGN.IS_ENABLED            true [get_runs impl_1]
set_property STEPS.POST_PLACE_POWER_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
puts "============================================================"
puts " Project: $project_dir"
puts " Part   : xc7z020clg400-1  (PYNQ-Z2)"
puts " Top    : accel_top_wrapper"
puts " RTL    : [llength $rtl_files] files"
puts " SIM    : [llength $sim_files] files"
puts " DSP    : 64 per engine (128 total / 220 = 58%)"
puts "============================================================"
