//Define simulation time scale: <time_unit>/<time_precision>
`timescale 1ns/10ps

module top_tb(
);
	//////////////////////////////////////////////////////////////////
	//              GLOBAL VARIABLES AND SIM CONSTANTS              //
	//Time constants in reference to timescale (ns)
	localparam SECOND       = 1_000_000_000;
	localparam MILLISECOND  = 1_000_000;
	localparam MICROSECOND  = 1_000;
	localparam NANOSECOND   = 1;
	localparam NANOSECOND_PER_SECOND = 1_000_000_000;

	//Frequency constants
	localparam CLOCK_FREQUENCY_HZ = 48_000_000; //12MHz
	localparam CLOCK_TIME_NS      = (1.0/CLOCK_FREQUENCY_HZ)*
					NANOSECOND_PER_SECOND;
	localparam PULSE_WIDTH_NS     = CLOCK_TIME_NS/2;
	//total sim time (in timescale units)
	localparam SIM_DURATION_NS    = 3*MILLISECOND;
	//localparam SIM_DURATION_NS    = 1*SECOND;

	//////////////////////////////////////////////////////////////////
	//                           FPGA CLOCK                         //
	//48MHz
	reg fpga_clk = 0;
	always begin
		//((1/48)*1000)/2
		#(10.41667)
		fpga_clk = ~fpga_clk;
	end
	//125MHz
	reg eth_rx_clk = 0;
	always begin
		#(4)
		eth_rx_clk = ~eth_rx_clk;
	end


	//////////////////////////////////////////////////////////////////
	//                         DISCRETE SIGNALS                     //
	//reg [15:0] fcw = 16'd1024;

	//////////////////////////////////////////////////////////////////
	//                         STORAGE ELEMENTS                     //
	// WARNING: Be careful when assigning default values to wires...//
	//          behaviour may be unpredictable.
	// TODO:    Research above warning with test benches.
	

	//////////////////////////////////////////////////////////////////
	//                       MODULE INSTANTIATION                  //

	wire [3:0] eth_tx_data;
	wire eth_tx_clk;
	wire eth_tx_ctrl;
	wire eth_tx_rstn;

	tx_phy tx_phy(
		.CLK48(fpga_clk),
		.ETH_RXCLK(eth_rx_clk),

		.ETH_TX(eth_tx_data),
		.ETH_TXCLK(eth_tx_clk),
		.ETH_TXCTRL(eth_tx_ctrl)
	);

	
	top top(
		.CLK48(fpga_clk),
		.ETH_RX_CLK(eth_tx_clk),
		.ETH_RX_CTRL(eth_tx_ctrl),
		.ETH_RX(eth_tx_data)
	);

	/////////////////////////////////////////////////////////////////
	//                        RUN SIMULATION                       //
	initial begin

		//create sim value change dump file
		$dumpfile("build/top.vcd");
		//0 means dump all variable levels to watch
		//1 is just test bench
		//2 is in UUt
		//3 is so on...
		$dumpvars(0, top_tb);

		//Wait for a given amount of time for sim to end

		#(SIM_DURATION_NS)

		$display("Finished!");
		$finish;

	end

endmodule
