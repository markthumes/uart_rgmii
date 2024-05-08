target=prog.bit
device=um5g-45k
speed=8
package=CABGA381
lpf=bcc.lpf

DEPS= \
	top.v \
	cores/fifo/fifo.v \
	cores/rgmii/rgmii_phy_rx.v \
	cores/rgmii/rgmii_phy_tx.v \
	cores/ddr/ddr.v \
	cores/clkdiv/clkdiv.v \
	cores/UART/Verilog/source/UART_TX.v \
	uart.v
	#/usr/share/yosys/ecp5/cells_bb.v

################ MAKE BITSTREAM ################

$(target): build/pnr.config
	mkdir -p build
	ecppack --spimod qspi --freq 38.8 --input $< --bit $@

################ PLACE AND ROUTE ################

build/pnr.config: build/synth.json
	mkdir -p build
	nextpnr-ecp5 \
		--json $< \
		--textcfg $@ \
		--$(device) \
		--speed $(speed) \
		--package $(package) \
		--lpf $(lpf)

################ SYNTHESIS ################

build/synth.json: $(DEPS)
	mkdir -p build
	yosys -p "read_verilog $(DEPS); synth_ecp5 -top top -json $@"

################ INSTALLATION ################

dfu: $(target)
	mkdir -p build
	cp $(target) build/$(target).dfu
	dfu-suffix -v 1209 -p bb80 -a build/$(target).dfu

install: dfu
	dfu-util -R -d 1209:bb80 -a 0 -D build/$(target).dfu

################ SIMULATION ################

sim: build/top.vcd
	gtkwave $<

build/top.vcd: build/sim.out
	vvp $<

build/sim.out: sim.v sender/sender.v $(DEPS)
	mkdir -p build
	iverilog -o $@ -DSIM -D VCD_OUTPUT=sim $< sender/sender.v $(DEPS)

update: build/top.vcd
	
.PHONY: clean

clean:
	rm -rf build
