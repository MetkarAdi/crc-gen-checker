RTL = rtl/crc32_serial.v
TB  = tb/tb_crc32_serial.v

sim: $(RTL) $(TB)
	iverilog -g2012 -o crc.vvp $(RTL) $(TB)
	vvp crc.vvp

lint:
	verilator --lint-only -Wall --top-module crc32_serial rtl/crc32_serial.v
	verilator --lint-only -Wall --top-module crc32_par rtl/crc32_par.v

wave: sim
	gtkwave crc.vcd

clean:
	rm -f *.vvp *.vcd vectors.hex

vectors.hex: scripts/gen_vectors.py
	python3 scripts/gen_vectors.py

simrand: vectors.hex rtl/crc32_serial.v tb/tb_crc32_rand.v
	iverilog -g2012 -o crc_rand.vvp rtl/crc32_serial.v tb/tb_crc32_rand.v
	vvp crc_rand.vvp

simpar: vectors.hex rtl/crc32_par.v tb/tb_crc32_par.v
	iverilog -g2012 -o crc_par.vvp rtl/crc32_par.v tb/tb_crc32_par.v
	vvp crc_par.vvp