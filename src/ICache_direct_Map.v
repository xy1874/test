`timescale 1ns / 1ps

`include "defines.vh"

module ICache_direct_map(
    input  wire         cpu_clk,
    input  wire         cpu_rst,        // high active
    // Interface to CPU
    input  wire         inst_rreq,
    input  wire [31:0]  inst_addr,
    output reg          inst_valid,
    output reg  [31:0]  inst_out,
    // Interface to Read Bus
    input  wire         dev_rrdy,       // device ready to be read
    output reg  [ 3:0]  cpu_ren,        // cpu read mask
    output reg  [31:0]  cpu_raddr,      // cpu read data address
    input  wire         dev_rvalid,     // device data valid
    input  wire [`IC_BLK_SIZE-1:0] dev_rdata   // data to be read
);

`ifdef ENABLE_ICACHE

    localparam READY     = 4'b0000,
               WAIT_TC   = 4'b0100,
               TAG_CHECK = 4'b0010,
               RD_MEM    = 4'b0001,
               REFILL    = 4'b0011;
    reg [ 3:0] current_state, next_state;

    wire [ 4:0] tag_from_cpu   = inst_addr[14:10];
    wire [ 3:0] offset         = inst_addr[3:0];
    wire        valid_bit      = cache_line_r[133];
    wire [ 4:0] tag_from_cache = cache_line_r[132:128];

    wire        hit  = (tag_from_cache == tag_from_cpu) && (valid_bit == 1) && (current_state == TAG_CHECK);
    wire        miss = (tag_from_cache != tag_from_cpu) | (~valid_bit);

    always @(*) begin
        inst_valid = hit;
        inst_out   = (offset[3:2] == 2'b00) ? cache_line_r[31:0] :
                     (offset[3:2] == 2'b01) ? cache_line_r[63:32] :
                     (offset[3:2] == 2'b10) ? cache_line_r[95:64] : cache_line_r[127:96];
    end

    wire         cache_we     = (current_state == REFILL) && dev_rvalid;
    wire [  5:0] cache_index  = inst_addr[9:4];
    wire [133:0] cache_line_w = {1'b1, tag_from_cpu, dev_rdata};
    wire [133:0] cache_line_r;

    blk_mem_gen_1 U_isram (
        .clka   (cpu_clk),
        .wea    (cache_we),
        .addra  (cache_index),
        .dina   (cache_line_w),
        .douta  (cache_line_r)
    );

    always @(posedge cpu_clk or posedge cpu_rst) begin
        current_state <= cpu_rst ? READY : next_state;
    end

    always @(*) begin
        case (current_state)
            READY:      next_state = inst_rreq ? WAIT_TC : READY;
            WAIT_TC:    next_state = TAG_CHECK;
            TAG_CHECK:  next_state = hit ? READY : RD_MEM;
            RD_MEM:     next_state = dev_rrdy ? REFILL : RD_MEM;
            REFILL:     next_state = dev_rvalid ? TAG_CHECK : REFILL;
            default:    next_state = READY;
        endcase
    end

    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            cpu_raddr <= 32'h0;
            cpu_ren   <= 4'h0;
        end else begin
            case (current_state)
                RD_MEM: begin
                    cpu_raddr <= dev_rrdy ? {inst_addr[31:4], 4'h0} : 32'h0;
                    cpu_ren   <= dev_rrdy ? 4'hF : 4'h0;
                end
                default: begin
                    cpu_raddr <= 32'h0;
                    cpu_ren   <= 4'h0;
                end
            endcase
        end
    end

`else

    localparam IDLE  = 2'b00;
    localparam STAT0 = 2'b01;
    localparam STAT1 = 2'b11;
    reg [1:0] state, nstat;

    always @(posedge cpu_clk or posedge cpu_rst) begin
        state <= cpu_rst ? IDLE : nstat;
    end

    always @(*) begin
        case (state)
            IDLE:    nstat = inst_rreq ? (dev_rrdy ? STAT1 : STAT0) : IDLE;
            STAT0:   nstat = dev_rrdy ? STAT1 : STAT0;
            STAT1:   nstat = dev_rvalid ? IDLE : STAT1;
            default: nstat = IDLE;
        endcase
    end

    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            inst_valid <= 1'b0;
            cpu_ren    <= 4'h0;
        end else begin
            case (state)
                IDLE: begin
                    inst_valid <= 1'b0;
                    cpu_ren    <= (inst_rreq & dev_rrdy) ? 4'hF : 4'h0;
                    cpu_raddr  <= inst_rreq ? inst_addr : 32'h0;
                end
                STAT0: begin
                    cpu_ren    <= dev_rrdy ? 4'hF : 4'h0;
                end
                STAT1: begin
                    cpu_ren    <= 4'h0;
                    inst_valid <= dev_rvalid ? 1'b1 : 1'b0;
                    inst_out   <= dev_rvalid ? dev_rdata[31:0] : 32'h0;
                end
                default: begin
                    inst_valid <= 1'b0;
                    cpu_ren    <= 4'h0;
                end
            endcase
        end
    end

`endif

endmodule
