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
	wire uart_read;
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
		.rinc(uart_read),
		.rempty(fifo_empty),
		.rrst_n(1'b1)
	);


	reg uart_tx_start = 0;
	wire uart_tx_active;
	wire tx_done;
	always @(posedge CLK48) begin
		if( !uart_tx_active || tx_done ) uart_tx_start <= 1;
		else  uart_tx_start <= 0;
	end

	//data is valid when fifo is not empty, and 
	localparam UART_SPEED = 48_000_000 / 115200;
	UART_TX #(UART_SPEED) uart_tx(
		.i_Clock(CLK48),
		.i_TX_DV(!fifo_empty && uart_tx_start),
		.i_TX_Byte(rgmii_to_uart_data),
		.o_TX_Active(uart_tx_active),
		.o_TX_Serial(UART_TX),
		.o_TX_Done(tx_done)
	);


endmodule
