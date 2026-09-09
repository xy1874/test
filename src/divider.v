`timescale 1ns / 1ps

module divider #(
    parameter WIDTH = 32
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [WIDTH-1:0] x,
    input  wire [WIDTH-1:0] y,
    input  wire       start,
    output wire [WIDTH-1:0] z,
    output reg  [WIDTH-1:0] r,
    output reg        busy     
);

    localparam LOG_W = $clog2(WIDTH);

    wire [WIDTH-1:0] x1 = x[WIDTH-1] ? {1'b1, {WIDTH{1'b0}}} - x[WIDTH-2:0] : x;
    reg  [WIDTH-1:0] x_r;
    reg  [WIDTH-1:0] y_r;
    reg  [LOG_W  :0] cnt;

    always @ (posedge clk or posedge rst) begin
        if (rst)        x_r <= 'h0;
        else if (start) x_r <= x;
    end

    always @ (posedge clk or posedge rst) begin
        if (rst)        y_r <= 'h0;
        else if (start) y_r <= y;
    end

    wire [WIDTH-1:0] y_r_p = {1'b0, y_r[WIDTH-2:0]};
    wire [WIDTH-1:0] y_r_n = {1'b1, {WIDTH{1'b0}}} - y_r[WIDTH-2:0];

    always @ (posedge clk or posedge rst) begin
        if (rst)        cnt <= 'h0;
        else if (start) cnt <= 'h0;
        else if (busy)  cnt <= cnt + 'h1;
    end

    wire x_smaller = x_r[WIDTH-2:0] < y_r[WIDTH-2:0];
    wire cnt_end   = (cnt == WIDTH - 1);

    always @ (posedge clk or posedge rst) begin
        if (rst)                      busy <= 1'b0;
        else if (start)               busy <= 1'b1;
        else if (cnt_end | x_smaller) busy <= 1'b0;
    end

    reg [WIDTH-1  :0] quotient;
    reg [2*WIDTH-1:0] remainder;

    wire [WIDTH-1:0] add_out = remainder[2*WIDTH-1:WIDTH] + y_r_p;
    wire [WIDTH-1:0] sub_out = remainder[2*WIDTH-1:WIDTH] + y_r_n;

    wire [2*WIDTH-1:0] mux_out1 = remainder[2*WIDTH-1] ? {add_out[WIDTH-2:0], remainder[WIDTH-1:0], 1'b0} : {sub_out[WIDTH-2:0], remainder[WIDTH-1:0], 1'b0};
    wire [2*WIDTH-1:0] mux_out2 = remainder[2*WIDTH-1] ? {add_out, remainder[WIDTH-1:0]} : {sub_out, remainder[WIDTH-1:0]};

    wire q_d = remainder[2*WIDTH-1] ? ~add_out[WIDTH-1] : ~sub_out[WIDTH-1];

    always @ (posedge clk or posedge rst) begin
        if (rst)        quotient <= 'h0;
        else if (start) quotient <= 'h0;
        else if (busy)  quotient <= {quotient[WIDTH-2:0], q_d};
    end

    always @ (posedge clk or posedge rst) begin
        if (rst)                 remainder <= 'h0;
        else if (start)          remainder <= {{WIDTH{1'h0}}, x[WIDTH-2:0], 1'b0};
        else if (busy & cnt_end) remainder <= mux_out2;
        else if (busy)           remainder <= mux_out1;
    end

    assign z = x_smaller ? {WIDTH{1'b0}} : {(x_r[WIDTH-1]^y_r[WIDTH-1]), quotient[WIDTH-2:0]};

    wire [WIDTH-1:0] r_d1 = mux_out2[2*WIDTH-1] ? mux_out2[2*WIDTH-1:WIDTH] + y_r_p : mux_out2[2*WIDTH-1:WIDTH];
    wire [WIDTH-1:0] r_d = x_r[WIDTH-1] ? {1'b1, r_d1[WIDTH-2:0]} : r_d1;

    always @ (posedge clk or posedge rst) begin
        if (rst)       r <= 'h0;
        else if (busy) r <= x_smaller ? x_r : r_d;
    end
	
endmodule
