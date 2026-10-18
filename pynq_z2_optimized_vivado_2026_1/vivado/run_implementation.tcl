# ============================================================================
# run_implementation.tcl – Full P&R + Power/Timing reports (Power Optimized)
# Vivado 2026.1  |  Part: xc7z020clg400-1  |  Board: PYNQ-Z2
# Run with: vivado -mode batch -source vivado/run_implementation.tcl
# ============================================================================

set script_dir [file dirname [file normalize [info script]]]
set root       [file normalize [file join $script_dir ..]]
set xpr_file   [file join $root vivado_build pynq_z2_systolic_optimized.xpr]

if {[file exists $xpr_file]} {
    puts "Opening existing project: $xpr_file"
    open_project $xpr_file
} else {
    source [file join $script_dir create_project.tcl]
}

set root [file normalize [file join $script_dir ..]]
set out  [file join $root reports vivado_impl]
file mkdir $out

# Run synthesis first if not already done
set synth_status [get_property STATUS [get_runs synth_1]]
if {![string match *Complete* $synth_status]} {
    puts "===== Running Synthesis first ====="
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    if {![string match *Complete* [get_property STATUS [get_runs synth_1]]]} {
        error "Synthesis failed: [get_property STATUS [get_runs synth_1]]"
    }
}

puts "===== Starting Implementation (Power Optimized) ====="
puts " power_opt_design     : ENABLED"
puts " post_place_power_opt : ENABLED"
puts " Route strategy       : AggressiveExplore"

# Run through route_design (no bitstream needed for IP core verification)
launch_runs impl_1 -to_step route_design -jobs 4
wait_on_run impl_1

if {![string match *Complete* [get_property STATUS [get_runs impl_1]]]} {
    error "Implementation did not complete: [get_property STATUS [get_runs impl_1]]"
}

open_run impl_1

# -----------------------------------------------------------------------
# Generate all implementation reports
# -----------------------------------------------------------------------
report_utilization -hierarchical \
    -file [file join $out utilization_routed_hier.rpt]
report_utilization \
    -file [file join $out utilization_routed_flat.rpt]
report_timing_summary -report_unconstrained \
    -file [file join $out timing_summary_routed.rpt]
report_route_status \
    -file [file join $out route_status.rpt]
report_power \
    -file [file join $out power_vectorless.rpt]
report_clock_interaction \
    -file [file join $out clock_interaction.rpt]

# -----------------------------------------------------------------------
# Timing check (must meet 100 MHz / 10 ns)
# -----------------------------------------------------------------------
set paths [get_timing_paths -delay_type max -max_paths 1 -quiet]
if {[llength $paths] == 0} {
    puts "WARNING: No setup timing path found; inspect timing_summary_routed.rpt"
} else {
    set wns [get_property SLACK $paths]
    puts "============================="
    puts " Routed WNS: $wns ns"
    if {$wns < 0} {
        error "100 MHz timing target FAILED: WNS=$wns ns — inspect timing report."
    } else {
        puts " TIMING: PASS (100 MHz met)"
    }
}

# DSP count verification
set dsp_cells [get_cells -hierarchical -filter {PRIMITIVE_SUBGROUP == dsp || REF_NAME =~ *DSP*} -quiet]
set dsp_count [llength $dsp_cells]
puts " DSP48E1 used : $dsp_count / 220"
puts " Target       : ~128 (64 per engine)"
if {$dsp_count > 160} {
    puts " WARNING: DSP count higher than expected — check RTL mapping."
}

puts "============================="
puts " Implementation reports written to: $out"
puts " Power report: power_vectorless.rpt"
puts " NOTE: Use SAIF/VCD for activity-annotated power estimate."
puts "============================="
