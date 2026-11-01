transcript on
if {![file exists work]} {
  vlib work
}
# UVM_HOME must point to the UVM source directory for your Questa installation.
# If your Questa release uses a precompiled UVM library, adapt this vlog command.
if {[info exists ::env(UVM_HOME)]} {
  set UVM_INC "+incdir+$::env(UVM_HOME)/src"
  vlog -sv $UVM_INC +incdir+tb rtl/uart_rx_reference.sv tb/uart_if.sv tb/uart_uvm_pkg.sv tb/tb_top.sv
} else {
  puts "ERROR: UVM_HOME is not set. Set it to your UVM source directory, or use your Questa precompiled UVM library."
  quit -code 1
}
vsim -voptargs=+acc work.tb_top
run -all
