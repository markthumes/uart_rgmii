module top(
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

	//When data is received over ethernet rx, save in a buffer
	wire [7:0] rx_data;
	wire [1:0] rx_dv;
	phy_rx #(
		.DELAY(0) //KSZ9031RNX PHY assds 1.2ns RX Delay
	) rx (
		//inputs
		.phy_clk(ETH_RXCLK),
		.phy_ctl(ETH_RXCTRL),
		.phy_data(ETH_RX),
		//outputs
		.data(rx_data),
		.ctl(rx_dv)
	);

	wire fifo_full; //Unused, fifo automatically limits when full and packets are dropped
	wire fifo_empty;
	wire [7:0] rgmii_to_uart_data;
	wire uart_tx_done;

	//Add a CDC fifo to send data from rgmii to uart
	fifo #(
		.DATASIZE(8),
		.ADDRSIZE(8)
	) rgmii_to_uart (
		//From PHY
		.wclk(ETH_RXCLK),
		//.wdata(temp_message[temp_index]),
		.wdata(rx_data),
		//.winc(temp_valid),
		.winc(rx_dv[0]),
		.wfull(fifo_full),
		.wrst_n(1'b1),
		
		//To UART
		.rclk(CLK48),
		.rdata(rgmii_to_uart_data),
		.rinc(uart_tx_done),
		.rempty(fifo_empty),
		.rrst_n(1'b1)
	);
	
	wire uart_tx_active;
	localparam START = "START";
	localparam IDLE  = "IDLE";
	localparam XFER  = "XFER";
	reg [$bits("START")-1:0] transfer_state = IDLE;
	always @(posedge CLK48) begin
		if( transfer_state == IDLE ) begin
			if( !fifo_empty ) transfer_state <= START;
		end else if( transfer_state == START ) begin
			transfer_state <= XFER;
		end else if( transfer_state == XFER) begin
			if( uart_tx_done ) transfer_state <= IDLE;
		end
	end

	//data is valid when fifo is not empty, and 
`ifdef SIM
	localparam UART_SPEED = 4;
`else
	localparam UART_SPEED = 48_000_000 / 115200;
`endif
	uart_tx #(
		.CLKS_PER_BIT(UART_SPEED)
	)uart_tx(
		//.i_Rst_L(1'b1),
		.i_Clock(CLK48),
		.i_Tx_DV(transfer_state == START),
		.i_Tx_Byte(rgmii_to_uart_data),
		.o_Tx_Active(PMOD_P7),
		.o_Tx_Serial(PMOD_P2),
		.o_Tx_Done(uart_tx_done)
	);

endmodule
