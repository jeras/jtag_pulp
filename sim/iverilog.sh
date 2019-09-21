iverilog -g2012 -s top_tb_jtag \
../src/bscell.sv \
../src/jtag_axi_wrap.sv \
../src/jtag_enable.sv \
../src/jtag_enable_synch.sv \
../src/jtagreg.sv \
../src/jtag_rst_synch.sv \
../src/jtag_sync.sv \
../src/tap_top.v \
../testbench/top_tb_jtag.v
