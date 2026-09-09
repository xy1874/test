`timescale 1ns / 1ps

module multiplier #(
    parameter WIDTH = 32
)(
    input  wire        clk,
	input  wire        rst,
	input  wire [WIDTH-1:0] x,
	input  wire [WIDTH-1:0] y,
	input  wire        start,
	output reg  [O_WID:0] z,
	output wire        busy 
);

    localparam LOG_W = $clog2(WIDTH);
    localparam O_WID = 2*WIDTH - 1  ;

    reg [WIDTH-1:0] x_s;
    reg [WIDTH-1:0] y_s;
    reg [LOG_W  :0] cnt;
    reg             cnt_period;
    reg [WIDTH  :0] y_r;

    always @ (posedge clk or posedge rst) begin
        if (rst)        x_s <= 'h0;
        else if (start) x_s <= x;
        // else if (!busy) x_s <= x;
    end

    always @ (posedge clk or posedge rst) begin
        if (rst)        y_s <= 'h0;
        else if (start) y_s <= y;
        // else if (!busy) y_s <= y;
    end

    wire [WIDTH-1:0] x_n_b = {1'b1, {WIDTH{1'b0}}} - x_s;  // 2's complement of -x
    wire [WIDTH:0] y_r_d = {y, 1'b0};

    wire cnt_end = cnt_period & (cnt == WIDTH - 1);

    always @ (posedge clk or posedge rst) begin
        if (rst)          cnt_period <= 1'b0;
        else if (cnt_end) cnt_period <= 1'b0;
        else if (start)   cnt_period <= 1'b1;
        // else if (!busy)   cnt_period <= 1'b1;
    end

    always @ (posedge clk or posedge rst) begin
        if (rst)             cnt <= 'h0;
        else if (cnt_end)    cnt <= 'h0;
        else if (cnt_period) cnt <= cnt + 'h1;
    end

    always @ (posedge clk or posedge rst) begin
        if (rst)             y_r <= 'h0;
        else if (start)      y_r <= y_r_d;
        // else if (!busy)      y_r <= y_r_d;
        else if (cnt_period) y_r <= (y_r >> 1);
    end

    wire op_0 = ~(y_r[1] ^ y_r[0]);
    wire op_1 = ~y_r[1] & y_r[0];

    wire [O_WID:0] z_d_o = op_0 ? z : op_1 ? z + {x_s, {WIDTH{1'b0}}} : z + {x_n_b, {WIDTH{1'b0}}};
    // for multiplication between integers
    wire [O_WID:0] z_d_s = {z_d_o[O_WID], z_d_o[O_WID:1]};
    // for multiplicatioin between proper fractions
    // wire [O_WID:0] z_d_s = cnt < LOG_W{1'b1} ? {z_d_o[O_WID], z_d_o[O_WID:1]} : z_d_o;

    always @ (posedge clk or posedge rst) begin
        if (rst)             z <= 'h0;
        else if (start)      z <= 'h0;
        // else if (!busy)      z <= 'h0;
        else if (cnt_period) z <= z_d_s;
    end

    assign busy = cnt_period;

    // wire [65:0] prod;
    // mult_gen_0 u_mul (
    //     .CLK    (clk),
    //     .A      (x),
    //     .B      (y),
    //     .P      (prod)
    // );

    // reg [65:0] prod_r;
    // always @(posedge clk) prod_r <= prod;

    // always @(*) z = prod_r;

    // reg busy_r;
    // assign busy = busy_r;
    // always @(posedge clk or posedge rst) begin
    //     busy_r  <= rst ? 1'b0 : start;
    //     // busy_rr <= rst ? 1'b0 : busy_r;
    // end
    
endmodule
