DEPS= \
	cores/fifo/fifo.v \
	cores/rgmii/rgmii_phy_rx.v \
	cores/ddr/ddr.v \
	cores/clkdiv/clkdiv.v \
	cores/UART/Verilog/source/UART_TX.v

sim: build/top.vcd
	gtkwave $<

build/top.vcd: build/sim.out
	vvp $<

build/sim.out: sim.v top.v tx_phy.v $(DEPS)
	mkdir -p build
	iverilog -o $@ -DSIM -D VCD_OUTPUT=sim $< top.v tx_phy.v $(DEPS)

update: build/top.vcd
	
.PHONY: clean

clean:
	rm -rf build
