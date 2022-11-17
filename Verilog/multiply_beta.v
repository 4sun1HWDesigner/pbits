
`include "header.vh"
`timescale 1ns/1ps


module multiply_beta (
    input clk,
    input reset_n,
    input signed [`MAC_TO_BETA-1:0] in,
    input signed [`BETA-1:0] beta,
    output reg signed [`BETA_TO_TANH-1:0] out
);

    // BETA_MULTIPLY_IN = BETA * IN
    reg signed [`BETA_MULTIPLY_IN-1:0] buffer_to_store_the_product_stage_1 = `BETA_MULTIPLY_IN'sb0;
    reg signed [`BETA_MULTIPLY_IN-1:0] buffer_to_store_the_product_stage_2 = `BETA_MULTIPLY_IN'sb0;
    reg signed [`BETA_MULTIPLY_IN-1:0] buffer_to_store_the_product_stage_3 = `BETA_MULTIPLY_IN'sb0;
    
    reg signed [`MAC_TO_BETA-1:0] in_stage_1 = `MAC_TO_BETA'sb0;
    reg signed [`MAC_TO_BETA-1:0] in_stage_2 = `MAC_TO_BETA'sb0;
    reg signed [`BETA-1:0] beta_reg = `BETA'sb0;
    
    
    always @(posedge clk) begin // input pipelining
        in_stage_1 <= in;
        beta_reg <= beta;
    end
    
    always @(posedge clk) begin // to use dsp48 in FPGA
        in_stage_2 <= in_stage_1;
    end
    
    // product using dsp48
    always @(posedge clk) begin // to use dsp48 in FPGA
        buffer_to_store_the_product_stage_1 <= in_stage_2 * beta_reg;
    end
    
    
    always @(posedge clk) begin // to use dsp48 in FPGA
        buffer_to_store_the_product_stage_2 <= buffer_to_store_the_product_stage_1;
    end
    
    always @(posedge clk) begin // to use dsp48 in FPGA
        buffer_to_store_the_product_stage_3 <= buffer_to_store_the_product_stage_2;
    end
    
    
    wire signed [`BETA_MULTIPLY_IN-1:0] product;
    assign product = buffer_to_store_the_product_stage_3;
  
  
    wire signed [`INTEGER_PART_OF_BETA_MULTIPLY_IN-1:0] integer_part_of_product; 
    assign integer_part_of_product = product[`BETA_MULTIPLY_IN-1-:`INTEGER_PART_OF_BETA_MULTIPLY_IN]; // decimal fraction: 4bit
    
    
    reg signed [`BETA_MULTIPLY_IN-1:0] product_reg = `BETA_MULTIPLY_IN'sb0;
   
    always @(*) begin
        case(product[`BETA_MULTIPLY_IN-1])
            1'b0: product_reg = (integer_part_of_product >= 3)?`BETA_MULTIPLY_IN'b0000_0000_0000_0000_0110_000:product;
            1'b1: product_reg = ((integer_part_of_product < -3) || ((integer_part_of_product == -3)&&!(|product[`DECIMAL_FRACTION_OF_BETA_MULTIPLY_IN-1:0])))?`BETA_MULTIPLY_IN'b1111_1111_1111_1111_1010_000:product; 
        endcase   
    end
  
    
    always @(posedge clk) begin
            if(!reset_n) begin
                out <= `BETA_TO_TANH'sb0;
            end
            else begin
                out <= {product_reg[`BETA_MULTIPLY_IN-1], product_reg[`BETA_TO_TANH-2:0]};
            end  
    end
    

endmodule
