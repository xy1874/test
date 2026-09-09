`timescale 1ns / 1ps

`define MADDR_SIZE 15       // 主存地址空间: 2^15 Bytes
`define CACHE_SIZE 10       // 2^10 Bytes
`define BLK_LEN    8        // Cache块包含的32位字的个数
`define BLK_SIZE   (`BLK_LEN*32)                    // Cache块大小 (bit)
`define BLK_BOFF   ($clog2(`BLK_LEN) + 2)           // 块内字节偏移量的位宽
`define BLK_NUM    (1 << (`CACHE_SIZE - `BLK_BOFF)) // Cache块个数
`define TAG_SIZE   (`MADDR_SIZE - `BLK_BOFF)        // 块标签大小 (bit)

module ICache_fully_map(
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
    input  wire [`BLK_SIZE-1:0] dev_rdata   // data to be read
);

`ifdef ENABLE_ICACHE

    localparam READY     = 4'b0000,
               TAG_CHECK = 4'b0010,
               RD_MEM    = 4'b0001,
               REFILL    = 4'b0011;
    reg [ 3:0] current_state, next_state;

    reg [`TAG_SIZE-1:0] tag  [`BLK_NUM-1:0];    // 块标签
    reg [`BLK_SIZE-1:0] data [`BLK_NUM-1:0];    // 数据块
    reg [`BLK_NUM -1:0] valid;                  // 有效位

    wire cache_we   = (current_state == REFILL) && dev_rvalid;
    wire cache_full = &valid;                   // 是否存在空闲块
    
    reg  [$clog2(`BLK_NUM)-1:0] free_index;     // 记录空闲Cache块的块号
    wire [$clog2(`BLK_NUM)-1:0] replace_index;  // 被替换Cache块的块号

    // 主存地址分解
    wire [`TAG_SIZE-1:0] tag_from_cpu = inst_addr[`MADDR_SIZE-1:`BLK_BOFF];
    wire [`BLK_BOFF-1:0] offset       = inst_addr[`BLK_BOFF-1:0];

    reg [`BLK_NUM -1:0] hit_i;      // 每个Cache块的命中信号
    reg [`BLK_SIZE-1:0] hit_blk;    // 命中的Cache块数据

    wire hit = |hit_i;

    integer i;
    always @(*) begin
        hit_blk = {`BLK_SIZE{1'b0}};
        for (i = 0; i < `BLK_NUM; i = i + 1) begin
            if (valid[i] && (tag[i] == tag_from_cpu) && (current_state == TAG_CHECK)) begin
                hit_i[i] = 1'b1;
            end else
                hit_i[i] = 1'b0;

            hit_blk = hit_blk | ({`BLK_SIZE{hit_i[i]}} & data[i]);
        end
    end

    // wire [7:0] blk_offset_base = offset[`BLK_BOFF-1:2] << 5;
    always @(*) begin
        inst_valid = hit;
        // inst_out   = hit_blk[blk_offset_base+ : 32];    // [blk_offset_base + 31 : blk_offset_base]
        inst_out   = (offset[4:2] == 3'h0) ? hit_blk[ 31:  0] :
                     (offset[4:2] == 3'h1) ? hit_blk[ 63: 32] :
                     (offset[4:2] == 3'h2) ? hit_blk[ 95: 64] :
                     (offset[4:2] == 3'h3) ? hit_blk[127: 96] :
                     (offset[4:2] == 3'h4) ? hit_blk[159:128] :
                     (offset[4:2] == 3'h5) ? hit_blk[191:160] :
                     (offset[4:2] == 3'h6) ? hit_blk[223:192] : hit_blk[255:224];
    end

    /********************************* 随机替换 **********************************/
    reg [$clog2(`BLK_NUM)-1:0] lfsr;            // LFSR随机数
    assign replace_index = lfsr;
    
    always @(posedge cpu_clk or posedge cpu_rst) begin
        lfsr <= cpu_rst ? 'h0 : {lfsr[3:0], lfsr[2] ^ lfsr[4]};
    end
    /******************************** 伪LRU替换 *********************************/
    // reg [1:0] lru_cnt [`BLK_NUM-1:0];
    // reg [$clog2(`BLK_NUM)-1:0] lru_min;         // lru_cnt最小的Cache块号
    // assign replace_index = lru_min;

    // integer j, k, l, m, n;
    // always @(posedge cpu_clk or posedge cpu_rst) begin
    //     if (cpu_rst) begin
    //         for (j = 0; j < `BLK_NUM; j = j + 1)
    //             lru_cnt[j] <= 2'b11;
    //     end else begin
    //         // 新加入的Cache块，令其lru_cnt为2'b11
    //         if (cache_we & !cache_full)
    //             lru_cnt[free_index]  <= 2'b11;
    //         else if (cache_we & cache_full)
    //             lru_cnt[replace_index] <= 2'b11;

    //         // 根据命中情况更新lru_cnt
    //         if (current_state == TAG_CHECK) begin
    //             for (j = 0; j < `BLK_NUM; j = j + 1)
    //                 if (hit_i[j])
    //                     lru_cnt[j] <= (lru_cnt[j] < 2'b11) ? lru_cnt[j] + 2'b01 : 2'b11;
    //                 else
    //                     lru_cnt[j] <= (lru_cnt[j] > 2'b00) ? lru_cnt[j] - 2'b01 : 2'b00;
    //         end
    //     end
    // end

    // // 使用比较树找出lru_cnt最小的Cache块号
    // reg [$clog2(`BLK_NUM)-1:0] lru_min1 [15:0];
    // reg [$clog2(`BLK_NUM)-1:0] lru_min2 [ 7:0];
    // reg [$clog2(`BLK_NUM)-1:0] lru_min3 [ 3:0];
    // reg [$clog2(`BLK_NUM)-1:0] lru_min4 [ 1:0];
    // always @(*) begin
    //     for (k = 0; k < `BLK_NUM; k = k + 2)
    //         lru_min1[k/2] = (lru_cnt[k] < lru_cnt[k + 1]) ? k : k + 1;
    //     for (l = 0; l < `BLK_NUM/2; l = l + 2)
    //         lru_min2[l/2] = (lru_cnt[lru_min1[l]] < lru_cnt[lru_min1[l + 1]]) ? lru_min1[l] : lru_min1[l + 1];
    //     for (m = 0; m < `BLK_NUM/4; m = m + 2)
    //         lru_min3[m/2] = (lru_cnt[lru_min2[m]] < lru_cnt[lru_min2[m + 1]]) ? lru_min2[m] : lru_min2[m + 1];
    //     for (n = 0; n < `BLK_NUM/8; n = n + 2)
    //         lru_min4[n/2] = (lru_cnt[lru_min3[n]] < lru_cnt[lru_min3[n + 1]]) ? lru_min3[n] : lru_min3[n + 1];

    //     lru_min = (lru_cnt[lru_min4[0]] < lru_cnt[lru_min4[1]]) ? lru_min4[0] : lru_min4[1];
    // end
    /*************************************************************************/
    
    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            valid      <= {`BLK_NUM{1'b0}};
            free_index <= {$clog2(`BLK_NUM){1'b0}};
        end else if (cache_we & !cache_full) begin      // 存在空闲的Cache块，直接写入
            valid[free_index] <= 1'b1;
            tag  [free_index] <= tag_from_cpu;
            data [free_index] <= dev_rdata;
            free_index        <= free_index + 1;
        end else if (cache_we & cache_full) begin       // 替换一个Cache块
            valid[replace_index] <= 1'b1;
            tag  [replace_index] <= tag_from_cpu;
            data [replace_index] <= dev_rdata;
        end
    end

    always @(posedge cpu_clk or posedge cpu_rst) begin
        current_state <= cpu_rst ? READY : next_state;
    end

    always @(*) begin
        case (current_state)
            READY:      next_state = inst_rreq ? TAG_CHECK : READY;
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
                    cpu_raddr <= dev_rrdy ? {inst_addr[31:`BLK_BOFF], {`BLK_BOFF{1'b0}}} : 32'h0;
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
