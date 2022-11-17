`include "header.vh"

`timescale 1ns / 1ps
module top_module_of_p_bits(

	input                              i_run,
	input               	           i_stop,
	input   [`M-1:0] i_m_0_initial,
	input   [`M-1:0] i_m_1_initial,
	input   signed [`BETA-1:0]         i_beta,
	input                              clk_mac,
	input                              clk_for_lfsr_0, 
	input                              clk_for_lfsr_1, // phase shifted by 180 degrees
	
	input                              reset_n,
	output   				           o_idle,
	output   				           o_running,
	output reg				           o_done,
	output [`M-1:0]  m_out_0,
	output [`M-1:0]  m_out_1
);

    // state machine
    localparam S_IDLE	= 2'b00;
    localparam S_RUN	= 2'b01;
    localparam S_DONE  	= 2'b10;
    
    
    reg [1:0] c_state; // current state  
    reg [1:0] n_state; // next state 
    
    wire	  is_done;
    
    // update state 
    always @(posedge clk_mac or negedge reset_n) begin
        if(!reset_n) begin
            c_state <= S_IDLE;
        end else begin
            c_state <= n_state;
        end
    end
    
    // compute next state
    always @(*) begin
        n_state = S_IDLE; // To prevent Latch.
        case(c_state)
           S_IDLE: if(i_run) begin
                        n_state = S_RUN;
                   end
           S_RUN : if(is_done) begin
                        n_state = S_DONE;
                   end
                   else begin 
                     n_state = S_RUN;
                   end
           S_DONE: n_state = S_IDLE;
        endcase
    end 
    
    // compute output
    always @(*) begin
        o_done = 0; // To prevent Latch.
        case(c_state)
           S_DONE: o_done = 1;
        endcase
    end
    
    assign o_idle 		= (c_state == S_IDLE);
    assign o_running 	= (c_state == S_RUN);
    
    
    assign is_done = o_running && i_stop;
    
    
    /// pbit cores interconnects each other
    
        reg [`M-1:0] m_in_to_P_BIT_0;
        wire [`M-1:0] m_out_from_P_BIT_0;
    
        p_bit_0 P_BIT_0 (
            .clk_mac(clk_mac),
            .clk_lfsr(clk_for_lfsr_0),
            .reset_n(reset_n),
            .i_beta(i_beta),
            .m_in(m_in_to_P_BIT_0),
            .m_out(m_out_from_P_BIT_0),
            .h_in(`H'b0)
        );
    
        reg [`M-1:0] m_in_to_P_BIT_1;
        wire [`M-1:0] m_out_from_P_BIT_1;
    
        p_bit_1 P_BIT_1 (
            .clk_mac(clk_mac),
            .clk_lfsr(clk_for_lfsr_1),
            .reset_n(reset_n),
            .i_beta(i_beta),
            .m_in(m_in_to_P_BIT_1),
            .m_out(m_out_from_P_BIT_1),
            .h_in(`H'b0)
        );
    
        // MUX to initialize m_0 & supply m from pbit_0
        always @(*) begin
            m_in_to_P_BIT_1 = i_m_0_initial;
            case(o_running)
                1'b0: m_in_to_P_BIT_1 = i_m_0_initial;
                1'b1: m_in_to_P_BIT_1 = m_out_from_P_BIT_0;
            endcase
        end
       
       
       // MUX to initialize m_1 & supply m from pbit_1
        always @(*) begin
            m_in_to_P_BIT_0 = i_m_1_initial;
            case(o_running)
                1'b0: m_in_to_P_BIT_0 = i_m_1_initial;
                1'b1: m_in_to_P_BIT_0 = m_out_from_P_BIT_1;
            endcase
        end 
        
        // get output
        assign m_out_0 = m_out_from_P_BIT_0;
        assign m_out_1 = m_out_from_P_BIT_1;

endmodule
