module top(
	input  wire CLK48,
	input  wire [1:0] BTN,
	output wire LED,
	output wire PROGRAMN,

	//UART
	input  wire UART_RX,
	output wire UART_TX,
	
	//Ethernet
	output wire ETH_RSTN,
	//Rx
	input  wire ETH_RX_CLK,
	input  wire ETH_RX_CTRL,
	input  wire [3:0] ETH_RX,
	//Tx
	output wire ETH_TX_CLK,
	output wire ETH_TX_CTRL,
	output wire [3:0] ETH_TX
);

	//When data is received over ethernet rx, save in a buffer
	wire [7:0] rx_data;
	wire [1:0] rx_dv;
	phy_rx rx(
		//inputs
		.phy_clk(ETH_RX_CLK),
		.phy_ctl(ETH_RX_CTRL),
		.phy_data(ETH_RX),
		//outputs
		.data(rx_data),
		.ctl(rx_dv)
	);

	wire fifo_full; //Unused, fifo automatically limits when full and packets are dropped
	wire fifo_empty;
	wire [7:0] rgmii_to_uart_data;

	//Add a CDC fifo to send data from rgmii to uart
	fifo #(.DATASIZE(8),.ADDRSIZE(8)) rgmii_to_uart(
		//From PHY
		.wclk(ETH_RX_CLK),
		.wdata(rx_data),
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


	
	wire uart_tx_done;
	wire uart_tx_active;
	reg [$bits("START")-1:0] transfer_state = "IDLE";
	always @(posedge CLK48) begin
		if( transfer_state == "IDLE" ) begin
			if( !fifo_empty ) transfer_state <= "START";
		end else if( transfer_state == "START" ) begin
			transfer_state <= "XFER";
		end else if( transfer_state == "XFER") begin
			if( uart_tx_done ) transfer_state <= "IDLE";
		end
	end

	//data is valid when fifo is not empty, and 
`ifdef SIM
	localparam UART_SPEED = 4;
`else
	localparam UART_SPEED = 48_000_000 / 115200;
`endif
	UART_TX #(UART_SPEED) uart_tx(
		.i_Clock(CLK48),
		.i_TX_DV(transfer_state == "START"),
		.i_TX_Byte(rgmii_to_uart_data),
		.o_TX_Active(uart_tx_active),
		.o_TX_Serial(UART_TX),
		.o_TX_Done(uart_tx_done)
	);


endmodule
