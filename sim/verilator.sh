verilator --lint-only -Wall --top-module tap_top \
../src/bscell.sv \
../src/jtag_axi_wrap.sv \
../src/jtag_enable.sv \
../src/jtag_enable_synch.sv \
../src/jtagreg.sv \
../src/jtag_rst_synch.sv \
../src/jtag_sync.sv \
../src/tap_top.sv
