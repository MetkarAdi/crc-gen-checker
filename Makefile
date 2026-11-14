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
	rm -f *.vvp *.vcd vectors.hex

vectors.hex: scripts/gen_vectors.py
	python3 scripts/gen_vectors.py

simrand: vectors.hex rtl/crc32_serial.v tb/tb_crc32_rand.v
	iverilog -g2012 -o crc_rand.vvp rtl/crc32_serial.v tb/tb_crc32_rand.v
	vvp crc_rand.vvp