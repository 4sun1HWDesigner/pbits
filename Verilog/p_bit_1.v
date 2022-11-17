`include "header.vh"

`timescale 1ns / 1ps
module p_bit_1
// Param

(
    input 	clk_mac,
    input   clk_lfsr,
    input 	reset_n,
	input	signed [`ARRAY_OF_M-1:0] m_in,
	input signed [`BETA-1:0] i_beta,
	input signed [`H-1:0] h_in,
	output signed [`M-1:0] m_out
);


// 1. get result value from MAC core

wire signed [`MAC_TO_BETA-1:0] out_mac_to_beta;

mac DUT_MAC(
	.m_in(m_in),
	.h_in(h_in),
	.out(out_mac_to_beta)
);


//2. send it to beta module

wire signed [`BETA_TO_TANH-1:0] out_beta_to_tanh;

multiply_beta DUT_BETA(
    
    .clk(clk_mac),
    .reset_n(reset_n),
	.in(out_mac_to_beta),
	.beta(i_beta),
	.out(out_beta_to_tanh)
);

// 3. send it to tanh module

wire [`TANH_TO_COMPARATOR-1:0] out_tanh_to_comparator;
reg [`TANH_TO_COMPARATOR-1:0] out_tanh_to_comparator_reg = 0;
wire [`TANH_TO_COMPARATOR-1:0] out_tanh_to_comparator_wire;

tanh DUT_TANH(
    .clk(clk_mac),
	.phase(out_beta_to_tanh),
	.tanh(out_tanh_to_comparator)
);

always @(posedge clk_mac) begin
    out_tanh_to_comparator_reg <= out_tanh_to_comparator;
end

assign out_tanh_to_comparator_wire = out_tanh_to_comparator_reg;

// 4. LFSR to generate random number and send Random number to comparator

wire [`LFSR_TO_COMPARATOR-1:0] out_lfsr_to_comparator;
reg [`LFSR_TO_COMPARATOR-1:0] out_lfsr_to_comparator_reg = 0;
wire [`LFSR_TO_COMPARATOR-1:0] out_lfsr_to_comparator_wire;

lfsr_1 DUT_LFSR(
	.clk(clk_lfsr),
	.out(out_lfsr_to_comparator)
);

always @(posedge clk_mac) begin
    out_lfsr_to_comparator_reg <= out_lfsr_to_comparator;
end

assign out_lfsr_to_comparator_wire = out_lfsr_to_comparator_reg;


// 5. comparator

reg [`M-1:0] m_out_reg;
wire [`M-1:0] m_out_wire;


comparator DUT_COMP(

	.in1(out_tanh_to_comparator_wire),
	.in2(out_lfsr_to_comparator_wire),
	.out(m_out_wire)
);


always @(posedge clk_mac or negedge reset_n) begin // buffer to meet timing(prevent setup violation)
    if(!reset_n) begin
        m_out_reg <= `M'b1;
    end
    else begin
        m_out_reg <= m_out_wire;
    end
end

assign m_out = m_out_reg;

endmodule
