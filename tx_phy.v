module tx_phy(
	input  wire CLK48,
	//Ethernet
	input  wire ETH_RXCLK,
	output wire [3:0] ETH_TX,
	output wire ETH_TXCLK,
	output wire ETH_TXCTRL,
	output wire ETH_RSTN
);
	wire ddr_out;

	wire clk_0;
	wire clk_1; //One second clock
	reg flipper = 0;
	reg eth_done = 0;

	wire ddr_clk;
	assign ddr_clk = ETH_RXCLK;

	assign ETH_RSTN = 1;

	//Where do we get our 125MHz clock from? (RXCLK or PLL)

	assign ETH_TXCLK = ddr_clk;


	localparam TOTAL_BYTES = 10;
	//In the format <inter-frame><preamble><sfd><data><efd>
	reg [7:0] datagram [0:TOTAL_BYTES];
	initial $readmemh("icmp.hex", datagram);

	//how do we want to send this data? msb first
	//we also only want to do so once a second
	//verilolg
	//We can do with a state machine
	localparam STATE_IDLE = 1'b0;
	localparam STATE_RUN  = 1'b1;
	reg state;
	initial state = STATE_IDLE;

	//handle state machine
	always @(posedge ETH_RXCLK) begin
		if( state == STATE_IDLE ) begin
			if( clk_1 ) state <= STATE_RUN;
		end else begin
			if( eth_done ) state <= STATE_IDLE;
		end
	end

	//Transmit data out
	reg [$clog2(TOTAL_BYTES)-1:0] byte_ctr = TOTAL_BYTES;
	reg [3:0] bit_ctr = 4'd7;
	wire [7:0] current_byte = datagram[TOTAL_BYTES-byte_ctr];
	//woah, these clocks are in different domains. Is this an issue?
	always @(posedge ddr_clk) begin
		if( state == STATE_RUN ) begin
			if( byte_ctr > 0 ) begin
				byte_ctr <= byte_ctr-1;
				if( byte_ctr == 1 ) eth_done <= 1;
			end else begin
				byte_ctr <= TOTAL_BYTES;
			end
		end
		else eth_done <= 0;
		
	end

	wire transfer;
	assign transfer = (state == STATE_RUN) && (byte_ctr > 0);

	//ethernet transfers one byte at a time using 4 lanes of DDR
	genvar i;
	generate
		for( i = 0; i < 4; i=i+1 ) begin
			wire [3:0] eth_tx_delay;
`ifdef SIM
			assign ETH_TX[i] = eth_tx_delay[i];
`else
			DELAYG #(
				.DEL_MODE("SCLK_CENTERED"),
				.DEL_VALUE(0)
			) delay (
				.A(eth_tx_delay[i]),
				.Z(ETH_TX[i])
			);
`endif
			oddr oddr(
				.D0(current_byte[i+0]), //Send LSB first
				.D1(current_byte[i+4]),
				.SCLK(ddr_clk),
				.Q(eth_tx_delay[i])
			);
		end
	endgenerate
	wire txctrl_delay;
`ifdef SIM
			assign ETH_TXCTRL = txctrl_delay;
`else
	DELAYG #(
		.DEL_MODE("SCLK_CENTERED"),
		.DEL_VALUE(0)
	) delay (
		.A(txctrl_delay),
		.Z(ETH_TXCTRL)
	);
`endif
	oddr oddr(
		.D0(transfer),
		.D1(transfer),
		.SCLK(ddr_clk),
		.Q(txctrl_delay)
	);

	clkdiv	#(10) clkdiv(
		.i_clk(ETH_RXCLK),
		.o_clk(clk_0)
	);

`ifndef SIM
	clkdiv	#(125_000_00) clkdiv_1s(
		.i_clk(ETH_RXCLK),
		.o_clk(clk_1)
	);
`else
	clkdiv	#(12500) clkdiv_1s(
		.i_clk(ETH_RXCLK),
		.o_clk(clk_1)
	);
`endif

	always @(posedge ETH_RXCLK) begin
		if( clk_0 ) flipper <= ~flipper;
	end

endmodule
