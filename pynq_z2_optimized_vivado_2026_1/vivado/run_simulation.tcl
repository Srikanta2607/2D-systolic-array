# ============================================================================
# run_simulation.tcl – Run all XSIM testbenches for the systolic array
# Vivado 2026.1  |  Part: xc7z020clg400-1
# Run with: vivado -mode batch -source vivado/run_simulation.tcl
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

set fs [get_filesets sim_1]
set sim_files [glob -nocomplain [file join $root sim *.sv]]
foreach f $sim_files {
    add_files -fileset sim_1 -norecurse [list [file normalize $f]] -quiet
}
set_property source_mgmt_mode All [current_project]
update_compile_order -fileset sim_1

# Ordered bench list: unit tests first, integration last
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

set pass_count 0
set fail_count 0

foreach bench $benches {
    puts "===== XSIM regression: $bench ====="
    if {[current_sim -quiet] ne ""} { close_sim -force }
    set_property top $bench $fs
    update_compile_order -fileset sim_1
    if {[catch {
        launch_simulation -simset sim_1 -mode behavioral
        run all
        close_sim -force
        incr pass_count
        puts "  PASS: $bench"
    } err]} {
        puts "  FAIL/NOTE: $bench — $err"
        incr fail_count
        if {[current_sim -quiet] ne ""} { close_sim -force }
    }
}

puts ""
puts "============================================================"
puts " SIMULATION COMPLETE"
puts " PASS: $pass_count / [llength $benches] benches"
puts "============================================================"
