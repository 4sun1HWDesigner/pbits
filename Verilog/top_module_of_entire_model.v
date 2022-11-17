`include "header.vh"

module top_module_of_entire_model #
(

	// User parameters ends
	// Do not modify the parameters beyond this line


	// Parameters of Axi Slave Bus Interface S00_AXI
	parameter integer C_S00_AXI_DATA_WIDTH	= 32,
	parameter integer C_S00_AXI_ADDR_WIDTH	= 5
)
(
	// Users to add ports here

	input wire 	s00_axi_aclk2,
	input wire  s00_axi_aclk3,
	// User ports ends
	// Do not modify the ports beyond this line


	// Ports of Axi Slave Bus Interface S00_AXI
	input wire  s00_axi_aclk,
	input wire  s00_axi_aresetn,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
	input wire [2 : 0] s00_axi_awprot,
	input wire  s00_axi_awvalid,
	output wire  s00_axi_awready,
	input wire signed [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
	input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input wire  s00_axi_wvalid,
	output wire  s00_axi_wready,
	output wire [1 : 0] s00_axi_bresp,
	output wire  s00_axi_bvalid,
	input wire  s00_axi_bready,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
	input wire [2 : 0] s00_axi_arprot,
	input wire  s00_axi_arvalid,
	output wire  s00_axi_arready,
	output wire signed [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
	output wire [1 : 0] s00_axi_rresp,
	output wire  s00_axi_rvalid,
	input wire  s00_axi_rready
);

// (edit)
	wire  						w_run;
	wire        	   			w_stop;
	wire   						w_idle;
	wire   						w_running;
	wire    					w_done;
	wire 	[`M-1:0]	w_m0;
	wire	[`M-1:0]	w_m1;
	wire    [`M-1:0]  w_m_0_initial;
	wire    [`M-1:0]  w_m_1_initial;
	wire      signed  [`BETA-1:0]     w_beta;
// Instantiation of Axi Bus Interface S00_AXI
	axi4 # ( 
		.C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) AXI4_DUT (

		// (edit) Users to add ports here
		.o_run		(w_run),
		.o_stop     (w_stop),
		.o_m_0_initial(w_m_0_initial),
		.o_m_1_initial(w_m_1_initial),
		.o_beta     (w_beta),
		.i_idle		(w_idle),
		.i_running	(w_running),
		.i_done		(w_done),
		.i_m0		(w_m0),
		.i_m1		(w_m1),

		.s00_axi_aclk	(s00_axi_aclk	),
		.s00_axi_aresetn(s00_axi_aresetn),
		.s00_axi_awaddr	(s00_axi_awaddr	),
		.s00_axi_awprot	(s00_axi_awprot	),
		.s00_axi_awvalid(s00_axi_awvalid),
		.s00_axi_awready(s00_axi_awready),
		.s00_axi_wdata	(s00_axi_wdata	),
		.s00_axi_wstrb	(s00_axi_wstrb	),
		.s00_axi_wvalid	(s00_axi_wvalid	),
		.s00_axi_wready	(s00_axi_wready	),
		.s00_axi_bresp	(s00_axi_bresp	),
		.s00_axi_bvalid	(s00_axi_bvalid	),
		.s00_axi_bready	(s00_axi_bready	),
		.s00_axi_araddr	(s00_axi_araddr	),
		.s00_axi_arprot	(s00_axi_arprot	),
		.s00_axi_arvalid(s00_axi_arvalid),
		.s00_axi_arready(s00_axi_arready),
		.s00_axi_rdata	(s00_axi_rdata	),
		.s00_axi_rresp	(s00_axi_rresp	),
		.s00_axi_rvalid	(s00_axi_rvalid	),
		.s00_axi_rready	(s00_axi_rready	)
	);

 
top_module_of_p_bits TOP_MODULE_OF_P_BITS (
    .clk_mac		(s00_axi_aclk),
	.clk_for_lfsr_0 		(s00_axi_aclk2),
	.clk_for_lfsr_1 		(s00_axi_aclk3),
    .reset_n	(s00_axi_aresetn),
	.i_run		(w_run),
	.i_stop     (w_stop),
	.i_m_0_initial(w_m_0_initial),
	.i_m_1_initial(w_m_1_initial),
	.i_beta(w_beta),
	.o_idle		(w_idle),
	.o_running	(w_running),
	.o_done		(w_done),
	.m_out_0		(w_m0),
	.m_out_1		(w_m1)
    );

endmodule
