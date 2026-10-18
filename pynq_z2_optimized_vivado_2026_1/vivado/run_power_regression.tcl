# Run only the 110-DSP-per-engine dual-engine self-checking regression in XSIM.
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir create_project.tcl]
set fs [get_filesets sim_1]
if {[current_sim -quiet] ne ""} { close_sim -force }
set_property top tb_power_regression $fs
update_compile_order -fileset sim_1
launch_simulation -simset sim_1 -mode behavioral
run all
close_sim -force
puts "PASS: tb_power_regression completed without a simulator fatal."
