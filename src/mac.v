`timescale 1ns / 1ps

module mac (
    input  wire        clk,
	input  wire        rst,
	input  wire [31:0] x,
	input  wire [31:0] y,
	input  wire        start,
	output wire [31:0] z,
	output wire        busy 
);

    wire [15:0] ele_res3, ele_res2, ele_res1, ele_res0;
    wire        ele_busy3, ele_busy2, ele_busy1, ele_busy0;

    wire [31:0] ext_ele_res3 = {{16{ele_res3[15]}}, ele_res3};
    wire [31:0] ext_ele_res2 = {{16{ele_res2[15]}}, ele_res2};
    wire [31:0] ext_ele_res1 = {{16{ele_res1[15]}}, ele_res1};
    wire [31:0] ext_ele_res0 = {{16{ele_res0[15]}}, ele_res0};

    assign z    = ext_ele_res3 + ext_ele_res2 + ext_ele_res1 + ext_ele_res0;
    assign busy = ele_busy3 | ele_busy2 | ele_busy1 | ele_busy0;
    
    multiplier #(8) U_mul3 (
        .clk    (clk),
        .rst    (rst),
        .x      (x[31:24]),
        .y      (y[31:24]),
        .start  (start),
        .z      (ele_res3),
        .busy   (ele_busy3)
    );

    multiplier #(8) U_mul2 (
        .clk    (clk),
        .rst    (rst),
        .x      (x[23:16]),
        .y      (y[23:16]),
        .start  (start),
        .z      (ele_res2),
        .busy   (ele_busy2)
    );

    multiplier #(8) U_mul1 (
        .clk    (clk),
        .rst    (rst),
        .x      (x[15:8]),
        .y      (y[15:8]),
        .start  (start),
        .z      (ele_res1),
        .busy   (ele_busy1)
    );

    multiplier #(8) U_mul0 (
        .clk    (clk),
        .rst    (rst),
        .x      (x[7:0]),
        .y      (y[7:0]),
        .start  (start),
        .z      (ele_res0),
        .busy   (ele_busy0)
    );
    
endmodule
