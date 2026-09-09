`timescale 1ns / 1ps

`include "defines.vh"

module DCache(
    input  wire         cpu_clk,
    input  wire         cpu_rst,        // high active
    // Interface to CPU
    input  wire [ 3:0]  data_ren,
    input  wire [31:0]  data_addr,
    output reg          data_valid,
    output reg  [31:0]  data_rdata,
    input  wire [ 3:0]  data_wen,
    input  wire [31:0]  data_wdata,
    output reg          data_wresp,
    // Interface to Write Bus
    input  wire         dev_wrdy,       // device ready to be written (device: main memory or peripherals)
    output reg  [ 3:0]  cpu_wen,        // cpu write enable
    output reg  [31:0]  cpu_waddr,      // cpu write data address
    output reg  [31:0]  cpu_wdata,      // cpu write data
    // Interface to Read Bus
    input  wire         dev_rrdy,       // device ready to be read
    output reg  [ 3:0]  cpu_ren,        // cpu read mask
    output reg  [31:0]  cpu_raddr,      // cpu read data address
    input  wire         dev_rvalid,     // device data valid
    input  wire [127:0] dev_rdata   // data to be read
);

`ifdef ENABLE_DCACHE

    localparam READY     = 4'b0000,
               TAG_CHECK = 4'b0010,
               RD_MEM    = 4'b0001,
               REFILL    = 4'b0011;
    reg  [ 3:0] current_state, next_state;

    reg  [ 3:0] data_ren_r;
    reg  [ 3:0] data_wen_r;
    reg  [31:0] data_addr_r;

    wire        daccess_flag   = (data_ren   != 4'h0) | (data_wen   != 4'h0);
    wire        daccess_flag_r = (data_ren_r != 4'h0) | (data_wen_r != 4'h0);
    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst)           data_addr_r <= 32'h0;
        else if (daccess_flag) data_addr_r <= data_addr;
    end

    wire [21:0] tag_from_cpu   = data_addr_r[31:10];
    wire [ 3:0] offset         = data_addr_r[3:0];
    wire        valid_bit      = cache_line_r[150];
    wire [21:0] tag_from_cache = cache_line_r[149:128];

    wire hit_r    = (tag_from_cache == tag_from_cpu) && (valid_bit == 1) && (current_state == TAG_CHECK);
    wire hit_w    = (tag_from_cache == tag_from_cpu) && (valid_bit == 1) && (w_current_state == W_TAG_CHECK);
    wire miss     = (tag_from_cache != tag_from_cpu) | (~valid_bit);
    
    // Peripherals access should be uncached.
    wire uncached = (data_addr  [31:16] == 16'hFFFF) & daccess_flag |
                    (data_addr_r[31:16] == 16'hFFFF) & daccess_flag_r ? 1'b1 : 1'b0;

    always @(*) begin
        data_valid = hit_r | dev_rvalid & uncached;
        data_rdata = uncached ? dev_rdata[31:0] :
                     (offset[3:2] == 2'b00) ? cache_line_r[31:0] :
                     (offset[3:2] == 2'b01) ? cache_line_r[63:32] :
                     (offset[3:2] == 2'b10) ? cache_line_r[95:64] : cache_line_r[127:96];
    end

    reg  [150:0] wr_cache_data;
    wire         cache_we     = ((current_state == REFILL) & dev_rvalid) | (hit_w & (|data_wen_r));
    wire [  5:0] cache_index  = cache_we ? data_addr_r[9:4] : data_addr[9:4];
    wire [150:0] cache_line_w = hit_w ? wr_cache_data : {1'b1, tag_from_cpu, dev_rdata};
    wire [150:0] cache_line_r;

    blk_mem_gen_1 U_dsram (
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
            READY:      next_state = (|data_ren) ? (uncached ? RD_MEM : TAG_CHECK) : READY;
            TAG_CHECK:  next_state = hit_r ? READY : RD_MEM;
            RD_MEM:     next_state = dev_rrdy ? REFILL : RD_MEM;
            REFILL:     next_state = dev_rvalid ? (uncached ? READY : TAG_CHECK) : REFILL;
            default:    next_state = READY;
        endcase
    end

    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            data_ren_r <= 4'h0;
            cpu_raddr  <= 32'h0;
            cpu_ren    <= 4'h0;
        end else begin
            case (current_state)
                READY: begin
                    cpu_raddr <= 32'h0;
                    cpu_ren   <= 4'h0;
                    if (|data_ren) begin
                        data_ren_r <= data_ren;
                        cpu_raddr  <= uncached ? data_addr : {data_addr[31:4], 4'h0};
                    end else
                        data_ren_r <= 4'h0;
                end
                RD_MEM: begin
                    cpu_ren    <= dev_rrdy ? data_ren_r : 4'h0;
                end
                default: begin
                    cpu_ren    <= 4'h0;
                end
            endcase
        end
    end

    localparam W_READY     = 4'b0000,
               W_TAG_CHECK = 4'b0010,
               W_WR_DATA   = 4'b0001,
               W_WAIT_RESP = 4'b0011;
    reg  [3:0] w_current_state, w_next_state;

    wire       wr_resp = (dev_wrdy & (cpu_wen == 4'h0)) ? 1'b1 : 1'b0;
    
    always @(posedge cpu_clk or posedge cpu_rst) begin
        w_current_state <= cpu_rst ? W_READY : w_next_state;
    end

    always @(*) begin
        case (w_current_state)
            W_READY:     w_next_state = (|data_wen) ? (uncached ? W_WR_DATA : W_TAG_CHECK) : W_READY;
            W_TAG_CHECK: w_next_state = W_WR_DATA;
            W_WR_DATA:   w_next_state = dev_wrdy ? W_WAIT_RESP : W_WR_DATA;
            W_WAIT_RESP:
                if (|data_wen)
                    w_next_state = uncached ? W_WR_DATA : W_TAG_CHECK;
                else
                    w_next_state = wr_resp ? W_READY : W_WAIT_RESP;
            default:     w_next_state = W_READY;
        endcase
    end

    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            data_wresp <= 1'b0;
            data_wen_r <= 4'h0;
            cpu_wen    <= 4'h0;
            cpu_waddr  <= 32'h0;
            cpu_wdata  <= 32'h0;
        end else begin
            case (w_current_state)
                W_READY: begin
                    data_wresp <= 1'b0;
                    cpu_wen    <= 4'h0;
                    if (|data_wen) begin
                        data_wen_r <= data_wen;
                        cpu_waddr  <= data_addr;
                        cpu_wdata  <= data_wdata;
                    end else
                        data_wen_r <= 4'h0;
                end
                W_TAG_CHECK: begin
                    data_wresp <= 1'b0;
                    cpu_wen    <= 4'h0;
                end
                W_WR_DATA: begin
                    data_wresp <= 1'b0;
                    cpu_wen    <= {4{dev_wrdy}} & data_wen_r;
                end
                W_WAIT_RESP: begin
                    data_wresp <= wr_resp ? 1'b1 : 1'b0;
                    cpu_wen    <= 4'h0;
                    if (|data_wen) begin
                        data_wen_r <= data_wen;
                        cpu_waddr  <= data_addr_r;
                        cpu_wdata  <= data_wdata;
                    end else
                        data_wen_r <= 4'h0;
                end
                default: begin
                    data_wresp <= 1'b0;
                    cpu_wen    <= 4'h0;
                    cpu_waddr  <= 32'h0;
                    cpu_wdata  <= 32'h0;
                end
            endcase
        end
    end

    always @(*) begin
        case (data_addr_r[3:2])
            2'h0: wr_cache_data = {cache_line_r[133:128], cache_line_r[127:32], 
                                    (data_wen_r[3] ? cpu_wdata[31:24] : cache_line_r[31:24]), 
                                    (data_wen_r[2] ? cpu_wdata[23:16] : cache_line_r[23:16]),
                                    (data_wen_r[1] ? cpu_wdata[15: 8] : cache_line_r[15: 8]),
                                    (data_wen_r[0] ? cpu_wdata[ 7: 0] : cache_line_r[ 7: 0])};
            2'h1: wr_cache_data = {cache_line_r[133:128], cache_line_r[127:64], 
                                    (data_wen_r[3] ? cpu_wdata[31:24] : cache_line_r[63:56]), 
                                    (data_wen_r[2] ? cpu_wdata[23:16] : cache_line_r[55:48]),
                                    (data_wen_r[1] ? cpu_wdata[15: 8] : cache_line_r[47:40]),
                                    (data_wen_r[0] ? cpu_wdata[ 7: 0] : cache_line_r[39:32]),
                                    cache_line_r[31:0]};
            2'h2: wr_cache_data = {cache_line_r[133:128], cache_line_r[127:96], 
                                    (data_wen_r[3] ? cpu_wdata[31:24] : cache_line_r[95:88]), 
                                    (data_wen_r[2] ? cpu_wdata[23:16] : cache_line_r[87:80]),
                                    (data_wen_r[1] ? cpu_wdata[15: 8] : cache_line_r[79:72]),
                                    (data_wen_r[0] ? cpu_wdata[ 7: 0] : cache_line_r[71:64]),
                                    cache_line_r[63:0]};
            2'h3: wr_cache_data = {cache_line_r[133:128], 
                                    (data_wen_r[3] ? cpu_wdata[31:24] : cache_line_r[127:120]), 
                                    (data_wen_r[2] ? cpu_wdata[23:16] : cache_line_r[119:112]),
                                    (data_wen_r[1] ? cpu_wdata[15: 8] : cache_line_r[111:104]),
                                    (data_wen_r[0] ? cpu_wdata[ 7: 0] : cache_line_r[103: 96]),
                                    cache_line_r[95:0]};
            default: wr_cache_data = cache_line_r;
        endcase
        
    end

`else

    localparam R_IDLE  = 2'b00;
    localparam R_STAT0 = 2'b01;
    localparam R_STAT1 = 2'b11;
    reg [1:0] r_state, r_nstat;
    reg [3:0] ren_r;

    always @(posedge cpu_clk or posedge cpu_rst) begin
        r_state <= cpu_rst ? R_IDLE : r_nstat;
    end

    always @(*) begin
        case (r_state)
            R_IDLE:  r_nstat = (|data_ren) ? (dev_rrdy ? R_STAT1 : R_STAT0) : R_IDLE;
            R_STAT0: r_nstat = dev_rrdy ? R_STAT1 : R_STAT0;
            R_STAT1: r_nstat = dev_rvalid ? R_IDLE : R_STAT1;
            default: r_nstat = R_IDLE;
        endcase
    end

    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            data_valid <= 1'b0;
            cpu_ren    <= 4'h0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    data_valid <= 1'b0;

                    if (|data_ren) begin
                        if (dev_rrdy)
                            cpu_ren <= data_ren;
                        else
                            ren_r   <= data_ren;

                        cpu_raddr <= data_addr;
                    end else
                        cpu_ren   <= 4'h0;
                end
                R_STAT0: begin
                    cpu_ren    <= dev_rrdy ? ren_r : 4'h0;
                end   
                R_STAT1: begin
                    cpu_ren    <= 4'h0;
                    data_valid <= dev_rvalid ? 1'b1 : 1'b0;
                    data_rdata <= dev_rvalid ? dev_rdata : 32'h0;
                end
                default: begin
                    data_valid <= 1'b0;
                    cpu_ren    <= 4'h0;
                end 
            endcase
        end
    end

    localparam W_IDLE  = 2'b00;
    localparam W_STAT0 = 2'b01;
    localparam W_STAT1 = 2'b11;
    reg  [1:0] w_state, w_nstat;
    reg  [3:0] wen_r;
    wire       wr_resp = dev_wrdy & (cpu_wen == 4'h0) ? 1'b1 : 1'b0;

    always @(posedge cpu_clk or posedge cpu_rst) begin
        w_state <= cpu_rst ? W_IDLE : w_nstat;
    end

    always @(*) begin
        case (w_state)
            W_IDLE:  w_nstat = (|data_wen) ? (dev_wrdy ? W_STAT1 : W_STAT0) : W_IDLE;
            W_STAT0: w_nstat = dev_wrdy ? W_STAT1 : W_STAT0;
            W_STAT1: w_nstat = wr_resp ? W_IDLE : W_STAT1;
            default: w_nstat = W_IDLE;
        endcase
    end

    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            data_wresp <= 1'b0;
            cpu_wen    <= 4'h0;
        end else begin
            case (w_state)
                W_IDLE: begin
                    data_wresp <= 1'b0;

                    if (|data_wen) begin
                        if (dev_wrdy)
                            cpu_wen <= data_wen;
                        else
                            wen_r   <= data_wen;
                        
                        cpu_waddr  <= data_addr;
                        cpu_wdata  <= data_wdata;
                    end else
                        cpu_wen    <= 4'h0;
                end
                W_STAT0: begin
                    cpu_wen    <= dev_wrdy ? wen_r : 4'h0;
                end
                W_STAT1: begin
                    cpu_wen    <= 4'h0;
                    data_wresp <= wr_resp ? 1'b1 : 1'b0;
                end
                default: begin
                    data_wresp <= 1'b0;
                    cpu_wen    <= 4'h0;
                end
            endcase
        end
    end

`endif

endmodule
