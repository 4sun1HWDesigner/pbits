`include "header.vh"
`timescale 1ns/1ps

module lfsr_1(
    input clk,
    output reg [`LFSR_TO_COMPARATOR-1:0] out
);

reg [`LFSR-1:0] lfsr = `LFSR'b1000_0001_0101;

   always @(posedge clk) begin
         lfsr[`LFSR-1:1] <= lfsr[`LFSR-2:0];
         lfsr[0] <= ^{lfsr[11], lfsr[5], lfsr[3], lfsr[0]};
    end

always @(posedge clk) begin
        out <= lfsr[`LFSR-1-:`LFSR_TO_COMPARATOR];
end

endmodule