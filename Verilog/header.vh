`timescale 1ns/1ps

// USED IN MAC

`define ARRAY_OF_M `J*`M
`define H 16 // Bit of H
`define MAC_TO_BETA 16 // Number of bits of the connection line connecting the mac model and the beta model
`define DATA_BIT 16 // Bit of Internel data
`define J 1 // Number of J
`define M 1 // Number of Bits of M

// USED IN BETA

`define BETA 7 // Bit of Beta
`define BETA_TO_TANH 8 // Number of bits of the connection line connecting the beta model and the tanh model
`define BETA_MULTIPLY_IN 23 // Number of bits of the "beta*input data"
`define INTEGER_PART_OF_BETA_MULTIPLY_IN 19
`define DECIMAL_FRACTION_OF_BETA_MULTIPLY_IN 4

// USED IN TANH

`define PART_OF_PHASE_USED_TO_DETERMINE_ADDRESS 13
`define AW 12 // Address width
`define DECIMAL_FRACTION_OF_TANH 12
`define TANH_TO_COMPARATOR 9 // Number of bits of the connection line connecting the tanh model and the comparator model

//USED IN LFSR

`define LFSR_TO_COMPARATOR 9 // Number of bits of the connection line connecting the lfsr model and the comparator model
`define LFSR 12 // Number of Bits of Random Number


