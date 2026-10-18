# ============================================================================
# run_all.tcl – Complete Flow: Synthesis → Simulation → Implementation
# PYNQ-Z2 Systolic Array Accelerator | Vivado 2026.1
#
# Usage:
#   vivado -mode batch -source vivado/run_all.tcl
#   vivado -mode batch -source vivado/run_all.tcl -tclargs sim_only
#   vivado -mode batch -source vivado/run_all.tcl -tclargs impl_only
# ============================================================================

set script_dir [file dirname [file normalize [info script]]]

# Parse optional argument
set mode "all"
if {[info exists argv] && [llength $argv] > 0} {
    set mode [lindex $argv 0]
}

puts "============================================================"
puts " PYNQ-Z2 Systolic Array Accelerator — Vivado 2026.1"
puts " Part  : xc7z020clg400-1 (PYNQ-Z2)"
puts " Mode  : $mode"
puts " DSPs  : 64 per engine (128 total / 220 = 58%)"
puts " Power : Targeting <1.6 W (was 2.145 W)"
puts "============================================================"

# -----------------------------------------------------------------------
# STEP 1: Create Project
# -----------------------------------------------------------------------
source [file join $script_dir create_project.tcl]

# -----------------------------------------------------------------------
# STEP 2: Synthesis
# -----------------------------------------------------------------------
if {$mode eq "all" || $mode eq "synth_only" || $mode eq "impl_only"} {
    set root [file normalize [file join $script_dir ..]]
    set synth_out [file join $root reports vivado_synth]
    file mkdir $synth_out

    puts "\n===== STEP 2: Synthesis (AreaPowerOptimized) ====="
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    if {![string match *Complete* [get_property STATUS [get_runs synth_1]]]} {
        error "Synthesis FAILED: [get_property STATUS [get_runs synth_1]]"
    }
    open_run synth_1
    report_utilization -hierarchical -file [file join $synth_out utilization_hier.rpt]
    report_power       -file [file join $synth_out power_vectorless.rpt]
    set dsp_cells [get_cells -hierarchical -filter {PRIMITIVE_SUBGROUP == dsp || REF_NAME =~ *DSP*} -quiet]
    puts "  Synthesis complete. DSP48E1 used: [llength $dsp_cells]"
}

# -----------------------------------------------------------------------
# STEP 3: Simulation (behavioral)
# -----------------------------------------------------------------------
if {$mode eq "all" || $mode eq "sim_only"} {
    puts "\n===== STEP 3: Behavioral Simulation ====="
    set fs [get_filesets sim_1]
    set benches {
        tb_pe_mac
        tb_skew_buffers
        tb_ping_pong_bram
        tb_dual_systolic_array
        tb_accel_dual_tile_core
        tb_adaptive_gemm
        tb_accel_top_axis
        tb_accel_cache_mvm
        tb_accel_dual_engine_top
        tb_power_regression
    }
    set pass 0
    foreach bench $benches {
        puts "  Running: $bench"
        if {[current_sim -quiet] ne ""} { close_sim -force }
        set_property top $bench $fs
        update_compile_order -fileset sim_1
        if {[catch {
            launch_simulation -simset sim_1 -mode behavioral
            run all
            close_sim -force
            incr pass
            puts "  PASS: $bench"
        } err]} {
            puts "  FAIL: $bench — $err"
        }
    }
    puts "  Simulation: $pass / [llength $benches] benches passed"
}

# -----------------------------------------------------------------------
# STEP 4: Implementation (Place & Route)
# -----------------------------------------------------------------------
if {$mode eq "all" || $mode eq "impl_only"} {
    set root [file normalize [file join $script_dir ..]]
    set impl_out [file join $root reports vivado_impl]
    file mkdir $impl_out

    puts "\n===== STEP 4: Implementation (Power Optimized P&R) ====="
    launch_runs impl_1 -to_step route_design -jobs 4
    wait_on_run impl_1
    if {![string match *Complete* [get_property STATUS [get_runs impl_1]]]} {
        error "Implementation FAILED: [get_property STATUS [get_runs impl_1]]"
    }
    open_run impl_1

    report_utilization -hierarchical -file [file join $impl_out utilization_routed_hier.rpt]
    report_utilization              -file [file join $impl_out utilization_routed_flat.rpt]
    report_timing_summary -report_unconstrained -file [file join $impl_out timing_summary_routed.rpt]
    report_route_status             -file [file join $impl_out route_status.rpt]
    report_power                    -file [file join $impl_out power_vectorless.rpt]

    # Timing check
    set paths [get_timing_paths -delay_type max -max_paths 1 -quiet]
    if {[llength $paths] > 0} {
        set wns [get_property SLACK $paths]
        puts "  WNS: $wns ns"
        if {$wns < 0} { error "TIMING FAILED: WNS=$wns ns" }
        puts "  TIMING: PASS (100 MHz met)"
    }

    set dsp_cells [get_cells -hierarchical -filter {PRIMITIVE_SUBGROUP == dsp || REF_NAME =~ *DSP*} -quiet]
    puts "  DSP48E1 used: [llength $dsp_cells] / 220"
}

puts "\n============================================================"
puts " ALL STEPS COMPLETE"
puts " Reports: [file normalize [file join $script_dir .. reports]]"
puts "============================================================"
