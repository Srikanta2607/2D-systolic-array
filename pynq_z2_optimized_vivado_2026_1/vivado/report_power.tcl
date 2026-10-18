# Vectorless Vivado estimate. For workload-based analysis, annotate SAIF/VCD
# activity from a matching implementation and use report_power in that run.
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
report_power -file [file join $out power_vectorless.rpt]
puts "Vectorless power estimate written to [file join $out power_vectorless.rpt]"
