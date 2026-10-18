# In an open project, report utilization for the synthesized or routed design.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root reports vivado_manual]
file mkdir $out
set run [get_runs -quiet impl_1]
if {$run ne "" && [string match *Complete* [get_property STATUS $run]]} {
    open_run impl_1
} else {
    set run [get_runs -quiet synth_1]
    if {$run eq "" || ![string match *Complete* [get_property STATUS $run]]} {
        error "Run synthesis or implementation first."
    }
    open_run synth_1
}
report_utilization -hierarchical -file [file join $out utilization_hier.rpt]
report_timing_summary -report_unconstrained -file [file join $out timing_summary.rpt]
puts "Resource and timing reports written to $out"
