`timescale 1ns / 1ps

`include "defines.vh"

module ALU (
    input  wire         rst,
    input  wire         clk,
    input  wire [ 4:0]  op,
    input  wire [31:0]  a,
    input  wire [31:0]  b,
    input  wire [31:0]  sum,
    
    output reg  [31:0]  c,
    output reg          br,
    output wire         busy
);

    wire        mul_flag, mulu_flag;
    wire [63:0] mul_res , mulu_res ;
    wire        mul_busy, mulu_busy;
    wire        div_flag, divu_flag;
    wire [31:0] div_quo , divu_quo ;    // quotient
    wire [31:0] div_rem , divu_rem ;    // remainder
    wire        div_busy, divu_busy;
    wire        mac_flag;
    wire [31:0] mac_res;
    wire        mac_busy;
    reg  [ 4:0] op_r;

    always @(*) begin
        case (op | op_r)
            `ALU_ADD  : c = a + b;
            `ALU_SUB  : c = a + ~b + 32'b1;
            `ALU_AND  : c = a & b;
            `ALU_OR   : c = a | b;
            `ALU_XOR  : c = a ^ b;
            `ALU_SLL  : c = a << b[4:0];
            `ALU_SRL  : c = a >> b[4:0];
            `ALU_SRA  : c = $signed(a) >>> b[4:0];
            `ALU_SLT  : c = $signed(a) < $signed(b);
            `ALU_SLTU : c = $unsigned(a) < $unsigned(b);
            `ALU_MUL  : c = mul_res[31:0];
            `ALU_MULH : c = mul_res[63:32];
            `ALU_MULHU: c = mulu_res[63:32];
            `ALU_DIV  : c = div_quo[31] ? {1'b1, ~div_quo[30:0] + 31'h1} : div_quo;
            // `ALU_DIV  : c = div_quo;
            `ALU_DIVU : c = divu_quo;
            `ALU_REM  : c = div_rem[31] ? {1'b1, ~div_rem[30:0] + 31'h1} : div_rem;
            // `ALU_REM  : c = div_rem;
            `ALU_REMU : c = divu_rem;
            `ALU_MAC4 : c = sum + mac_res;
            default   : c = 32'h0;
        endcase
    end

    always @(*) begin
        case (op)
            `ALU_EQ : br = a == b;
            `ALU_NE : br = a != b;
            `ALU_LT : br = $signed(a) < $signed(b);
            `ALU_GE : br = $signed(a) >= $signed(b);
            `ALU_LTU: br = $unsigned(a) < $unsigned(b);
            `ALU_GEU: br = $unsigned(a) >= $unsigned(b);
            default : br = 1'b0;
        endcase
    end

    assign mul_flag  = (op == `ALU_MUL) | (op == `ALU_MULH);
    assign mulu_flag = (op == `ALU_MULHU);
    assign div_flag  = (op == `ALU_DIV) | (op == `ALU_REM);
    assign divu_flag = (op == `ALU_DIVU) | (op == `ALU_REMU);
    assign mac_flag  = (op == `ALU_MAC4);
    assign busy      = mul_busy | mulu_busy | div_busy | divu_busy | mac_busy;

    always @(posedge clk) begin
        if (mul_flag | mulu_flag | div_flag | divu_flag | mac_flag)
            op_r <= op;
        else if (!busy)
            op_r <= 4'h0;
    end

    multiplier #(32) U_mul (
    // multiplier #(33) U_mul (
        .clk    (clk),
        .rst    (rst),
        .x      ({a[31], a}),
        .y      ({b[31], b}),
        .start  (mul_flag),
        .z      (mul_res),
        .busy   (mul_busy)
    );

    multiplier #(33) U_mulu (
        .clk    (clk),
        .rst    (rst),
        .x      ({1'b0, a}),
        .y      ({1'b0, b}),
        .start  (mulu_flag),
        .z      (mulu_res),
        .busy   (mulu_busy)
    );

    divider #(32) U_div (
        .clk    (clk),
        .rst    (rst),
        .x      (a[31] ? {1'b1, ~a[30:0] + 31'h1} : a),
        .y      (b[31] ? {1'b1, ~b[30:0] + 31'h1} : b),
        .start  (div_flag),
        .z      (div_quo),
        .r      (div_rem),
        .busy   (div_busy)
    );

    divider #(33) U_divu (
        .clk    (clk),
        .rst    (rst),
        .x      ({1'b0, a}),
        .y      ({1'b0, b}),
        .start  (divu_flag),
        .z      (divu_quo),
        .r      (divu_rem),
        .busy   (divu_busy)
    );

    // reg div_busy_r, divu_busy_r;
    // wire div_tvalid, divu_tvalid;
    // assign div_busy  = div_busy_r  & !div_tvalid;
    // assign divu_busy = divu_busy_r & !divu_tvalid;
    // always @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         div_busy_r  <= 1'b0;
    //         divu_busy_r <= 1'b0;
    //     end else begin
    //         if (div_flag)   div_busy_r <= 1'b1;
    //         if (div_tvalid) div_busy_r <= 1'b0;
    //         if (divu_flag)   divu_busy_r <= 1'b1;
    //         if (divu_tvalid) divu_busy_r <= 1'b0;
    //     end
    // end
    // div_gen_0 u_div (
    //     .aclk                   (clk),
    //     .s_axis_dividend_tvalid (div_flag),
    //     .s_axis_dividend_tdata  (a),
    //     .s_axis_divisor_tvalid  (div_flag),
    //     .s_axis_divisor_tdata   (b),
    //     .m_axis_dout_tvalid     (div_tvalid),
    //     .m_axis_dout_tdata      ({div_quo, div_rem})
    // );

    // div_gen_1 u_divu (
    //     .aclk                   (clk),
    //     .s_axis_dividend_tvalid (divu_flag),
    //     .s_axis_dividend_tdata  (a),
    //     .s_axis_divisor_tvalid  (divu_flag),
    //     .s_axis_divisor_tdata   (b),
    //     .m_axis_dout_tvalid     (divu_tvalid),
    //     .m_axis_dout_tdata      ({divu_quo, divu_rem})
    // );

    mac U_mac (
        .clk    (clk),
        .rst    (rst),
        .x      (a),
        .y      (b),
        .start  (mac_flag),
        .z      (mac_res),
        .busy   (mac_busy)
    );

endmodule
