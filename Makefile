RTL = rtl/crc32_serial.v
TB  = tb/tb_crc32_serial.v

sim: $(RTL) $(TB)
	iverilog -g2012 -o crc.vvp $(RTL) $(TB)
	vvp crc.vvp

lint:
	verilator --lint-only -Wall --top-module crc32_serial $(RTL)

wave: sim
	gtkwave crc.vcd

clean:
	rm -f *.vvp *.vcd