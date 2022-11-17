`include "header.vh"

`timescale 1ns / 1ps

// tanh core

module tanh( clk, phase, tanh);

input clk;
input signed [`BETA_TO_TANH-1:0] phase;
output reg [`TANH_TO_COMPARATOR-1:0] tanh = 0;


(* ram_style = "block" *) reg [`AW-1:0] ADDR [(1 << `AW)-1:0]; // declaration of BRAM

initial begin
     $readmemh("intermediate_addr_table.mem", ADDR); // store the lookup table data to BRAM
     // this part is synthesizable only in Vivado!
end


(* ram_style = "block" *) reg [`DATA_BIT-1:0] mem [(1 << `AW)-1:0]; // declaration of BRAM

initial begin
     $readmemb("value_of_tanh.mem", mem); // store the lookup table data to BRAM
     // this part is synthesizable only in Vivado!
end


wire [`DATA_BIT-1:0] phase_attached_zero;

assign phase_attached_zero = {phase, 8'b0};


reg [`AW-1:0] intermediate_address;
reg [`AW-1:0] address_of_tanh_value;


always @(posedge clk) begin // To use BRAM, We must use Flip Flop.
    intermediate_address <= phase_attached_zero[`DATA_BIT-1]?(~phase_attached_zero[`PART_OF_PHASE_USED_TO_DETERMINE_ADDRESS-:`AW] + 1):(phase_attached_zero[`PART_OF_PHASE_USED_TO_DETERMINE_ADDRESS-:`AW]);
    address_of_tanh_value <= ADDR[intermediate_address];
end


reg [`DATA_BIT-1:0] tanh_reg = 0;

always @(*) begin
    case(phase_attached_zero[`DATA_BIT-1])
        1'b0: tanh_reg = (mem[address_of_tanh_value]);
        1'b1: tanh_reg = (~mem[address_of_tanh_value] + `DATA_BIT'b0001_0000_0000_0000);
    endcase
end

    always @(posedge clk) begin
        tanh <= tanh_reg[`DECIMAL_FRACTION_OF_TANH-1-:`TANH_TO_COMPARATOR];
    end
       
endmodule