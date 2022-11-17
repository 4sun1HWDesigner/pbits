`include "header.vh"

// m is -1 or 1
// calculate: J*m+h


module mac(
    input [`ARRAY_OF_M-1:0] m_in,
    input signed [`H-1:0] h_in,
    output signed [`MAC_TO_BETA-1:0] out
);

(* ram_style = "block" *) reg signed [`DATA_BIT-1:0] in [`J-1:0]; // declaration of BRAM

initial begin
     $readmemb("input_data_J.mem", in); // store the lookup table data to BRAM
     // this part is synthesizable only in Vivado!
end


genvar i;
integer j;

wire signed [`DATA_BIT-1:0] m_multiply_in [`J-1:0];

generate
    for(i = 0; i < `J; i = i + 1) begin: multiply_m_gen
        multiply_m MULT_M_DUT(
            .in(in[i]),
            .m_in(m_in[i*`M+:`M]),
            .out(m_multiply_in[i])
        );
    end
endgenerate


reg signed [`DATA_BIT-1:0] accumulation;

always @(*) begin
    accumulation = `DATA_BIT'sb0;
    for(j = 0;j < `J; j = j + 1 ) begin: accumulate_gen
        accumulation = accumulation + m_multiply_in[j];
    end
end

assign out = accumulation + h_in;

endmodule


module multiply_m(
    input signed [`DATA_BIT-1:0] in,
    input [`M-1:0] m_in,
    output signed [`DATA_BIT-1:0] out
);

    assign out = (m_in)?(in):(~in+1); 
    
endmodule