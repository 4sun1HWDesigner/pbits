`include "header.vh"

module comparator(
    input [`TANH_TO_COMPARATOR-1:0] in1,
    input [`LFSR_TO_COMPARATOR-1:0] in2,
    output [`M-1:0] out
);

assign out = (in1 >= in2)?(`M'b1):(`M'b0); // for buf gate
//assign out = (in1>= in2)?(2'sb11):(2'sb01); // for inverter

endmodule