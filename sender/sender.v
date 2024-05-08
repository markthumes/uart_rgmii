module sender(
	input  wire CLK48,
	input  wire [1:0] BTN,
	output wire LED,
	output wire PROGRAMN,

	//UART
	input  wire PMOD_P1,
	output wire PMOD_P2,

	output wire PMOD_P3,
	output wire PMOD_P4,
	output wire PMOD_P7,
	output wire PMOD_P8,
	output wire PMOD_P9,
	output wire PMOD_P10,
	
	//Ethernet
	output wire ETH_RSTN,
	//Rx
	input  wire ETH_RXCLK,
	input  wire ETH_RXCTRL,
	input  wire [3:0] ETH_RX,
	//Tx
	output wire ETH_TXCLK,
	output wire ETH_TXCTRL,
	output wire [3:0] ETH_TX
);
	assign PROGRAMN = BTN[0];
	assign ETH_RSTN = 1;

	assign PMOD_P7 = tx_msg[index][0];
	assign PMOD_P8 = tx_msg[index][1];
	assign PMOD_P9 = tx_msg[index][2];
	assign PMOD_P10 = ETH_RXCLK;
	
	localparam MSG_LEN = 79;
	reg [7:0] tx_msg[0:MSG_LEN-1];
	initial $readmemh("tx_msg.hex", tx_msg);

`ifdef SIM
	localparam RATE = 125_000_000 / 1_000_000;
`else
	localparam RATE = 125_000_000 / 1;
`endif
	
	localparam STATE_IDLE = "IDLE";
	localparam STATE_XMIT = "XMIT";
	reg [$bits(STATE_IDLE)-1:0] transmit_state = STATE_IDLE;

	//send data at a 10hz rate
	reg [$clog2(RATE)-1:0] rate_ctr = 0;
	reg tx_dv = 0;
	reg [$clog2(MSG_LEN)-1:0] index = 0;
	always @(posedge ETH_RXCLK) begin
		if( transmit_state == STATE_IDLE ) begin
			if( rate_ctr < RATE) begin
				rate_ctr <= rate_ctr + 1;
			end else begin
				rate_ctr <= 0;
				transmit_state <= STATE_XMIT;
			end
		end else begin
			if( index < MSG_LEN - 1 ) begin
				index <= index + 1;
			end else begin
				transmit_state <= STATE_IDLE;
				index <= 0;
			end
		end
	end

	phy_tx tx(
		.clk(ETH_RXCLK),
		.ctl(transmit_state == STATE_XMIT),
		.data(tx_msg[index]),
		.phy_clk(ETH_TXCLK),
		.phy_ctl(ETH_TXCTRL),
		.phy_data(ETH_TX)
	);

endmodule
