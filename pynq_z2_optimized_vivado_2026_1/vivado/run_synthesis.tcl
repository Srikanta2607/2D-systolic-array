# ============================================================================
# run_synthesis.tcl – Synthesize the PYNQ-Z2 Systolic Array (Power Optimized)
# Vivado 2026.1  |  Part: xc7z020clg400-1
# Run with: vivado -mode batch -source vivado/run_synthesis.tcl
# ============================================================================

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir create_project.tcl]

set root [file normalize [file join $script_dir ..]]
set out  [file join $root reports vivado_synth]
file mkdir $out

puts "===== Starting Synthesis ====="
puts " Strategy : AreaPowerOptimized"
puts " DSP Limit: 64 per engine (128 total)"

launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {![string match *Complete* [get_property STATUS [get_runs synth_1]]]} {
    error "Synthesis did not complete: [get_property STATUS [get_runs synth_1]]"
}

open_run synth_1

# -----------------------------------------------------------------------
# Generate all synthesis reports
# -----------------------------------------------------------------------
report_utilization -hierarchical \
    -file [file join $out utilization_hier.rpt]
report_utilization \
    -file [file join $out utilization_flat.rpt]
report_timing_summary -report_unconstrained \
    -file [file join $out timing_summary.rpt]
report_power \
    -file [file join $out power_vectorless.rpt]

# Quick DSP check
set dsp_cells [get_cells -hierarchical -filter {PRIMITIVE_SUBGROUP == dsp || REF_NAME =~ *DSP*} -quiet]
set dsp_count [llength $dsp_cells]
puts "============================="
puts " DSP48E1 used: $dsp_count (target: ~128, max allowed: 220)"
if {$dsp_count > 160} {
    puts " WARNING: DSP count ($dsp_count) exceeds 160. Check pe_mac MAC_IMPL mapping."
}
puts " Synthesis reports written to $out"
puts "============================="
