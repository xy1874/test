`timescale 1ns / 1ps

`include "defines.vh"

module axi_master(
    input  wire         aclk,
    input  wire         areset,     // high active

    // ICache Interface
    output reg          ic_dev_rrdy,
    input  wire         ic_cpu_ren,
    input  wire [31:0]  ic_cpu_raddr,
    output reg          ic_dev_rvalid,
    output reg  [`IC_BLK_SIZE-1:0]  ic_dev_rdata,
    // DCache Interface
    output reg          dc_dev_wrdy,
    input  wire [ 3:0]  dc_cpu_wen,
    input  wire [31:0]  dc_cpu_waddr,
    input  wire [31:0]  dc_cpu_wdata,
    output reg          dc_dev_rrdy,
    input  wire         dc_cpu_ren,
    input  wire [31:0]  dc_cpu_raddr,
    output reg          dc_dev_rvalid,
    output reg  [`DC_BLK_SIZE-1:0]  dc_dev_rdata,

    // AXI4 Master Interface
    // write address channel
    output reg  [31:0]  m_axi_awaddr,
    output reg  [ 7:0]  m_axi_awlen,
    output reg  [ 2:0]  m_axi_awsize,
    output reg  [ 1:0]  m_axi_awburst,
    output reg          m_axi_awvalid,
    input  wire         m_axi_awready,
    // write data channel
    output reg  [31:0]  m_axi_wdata,
    output reg  [ 3:0]  m_axi_wstrb,
    output wire         m_axi_wlast,
    output reg          m_axi_wvalid,
    input  wire         m_axi_wready,
    // write response channel
    output reg          m_axi_bready,
    input  wire [ 1:0]  m_axi_bresp,
    input  wire         m_axi_bvalid,
    // read address channel
    output reg  [31:0]  m_axi_araddr,
    output reg  [ 7:0]  m_axi_arlen,
    output reg  [ 2:0]  m_axi_arsize,
    output reg  [ 1:0]  m_axi_arburst,
    output reg          m_axi_arvalid,
    input  wire         m_axi_arready,
    // read data channel
    output reg          m_axi_rready,
    input  wire [31:0]  m_axi_rdata,
    input  wire [ 1:0]  m_axi_rresp,
    input  wire         m_axi_rlast,
    input  wire         m_axi_rvalid
);

    wire has_dc_wr_req = dc_dev_wrdy & (dc_cpu_wen != 4'h0);
    wire has_dc_rd_req = dc_dev_rrdy & dc_cpu_ren;
    wire has_ic_rd_req = ic_dev_rrdy & ic_cpu_ren;
    wire has_rd_req    = has_dc_rd_req | has_ic_rd_req;

    reg  has_dc_rd_req_r;
    reg  has_ic_rd_req_r;

    wire dc_uncached_rd = has_dc_rd_req   & (dc_cpu_raddr[31:16] == 32'hFFFF) |
                          has_dc_rd_req_r & (m_axi_araddr[31:16] == 32'hFFFF);

    ///////////////////////////////////////////////////////////////////////////
    // write address channel
    always @ (posedge aclk or posedge areset) begin
        if (areset) begin
            m_axi_awaddr  <= 32'h0;
            m_axi_awvalid <= 1'b0;
        end else begin
            if (m_axi_awvalid & m_axi_awready) begin
                m_axi_awvalid <= 1'b0;
                m_axi_awlen   <= 8'h0;
                m_axi_awsize  <= 3'h0;
                m_axi_awburst <= 2'h0;
            end else if (has_dc_wr_req) begin
                m_axi_awaddr  <= dc_cpu_waddr;
                m_axi_awlen   <= 8'h1 - 1;      // 1 packages each transaction
                m_axi_awsize  <= 3'h2;          // 2^2 bytes per package
                m_axi_awburst <= 2'h1;          // INCR addressing mode
                m_axi_awvalid <= 1'b1;
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // write data channel
    always @ (posedge aclk or posedge areset) begin
        if (areset) begin
            m_axi_wdata  <= 32'h0;
            m_axi_wstrb  <= 4'h0;
            m_axi_wvalid <= 1'b0;
        end else begin
            if (m_axi_wvalid & m_axi_wready) begin
                m_axi_wvalid <= 1'b0;
            end else if (has_dc_wr_req) begin
                m_axi_wdata  <= dc_cpu_wdata;
                m_axi_wstrb  <= dc_cpu_wen;
                m_axi_wvalid <= 1'b1;
            end
        end
    end

    assign m_axi_wlast = m_axi_wvalid;

    ///////////////////////////////////////////////////////////////////////////
    // write response channel
    always @ (posedge aclk or posedge areset) begin
        if (areset) begin
            dc_dev_wrdy     <= 1'b1;
        end else begin
            if (m_axi_bvalid) begin
                dc_dev_wrdy <= 1'b1;
            end else if (has_dc_wr_req) begin
                dc_dev_wrdy <= 1'b0;
            end
        end
    end

    always @ (posedge aclk or posedge areset) begin
        m_axi_bready <= areset ? 1'b0 : 1'b1;
    end

    ///////////////////////////////////////////////////////////////////////////
    // read address channel
    always @ (posedge aclk or posedge areset) begin
        if (areset) begin
            m_axi_araddr  <= 32'h0;
            m_axi_arlen   <= 8'h0;
            m_axi_arsize  <= 3'h0;
            m_axi_arburst <= 2'h0;
            m_axi_arvalid <= 1'b0;
        end else begin
            if (has_rd_req) begin
                m_axi_araddr  <= has_dc_rd_req ? dc_cpu_raddr : ic_cpu_raddr;
                m_axi_arlen   <= has_dc_rd_req ? (dc_uncached_rd ? 8'h0 : `DC_BLK_LEN - 1) : `IC_BLK_LEN - 1;  // 4 packages each transaction
                m_axi_arsize  <= 3'h2;          // 2^2 bytes each package
                m_axi_arburst <= 2'h1;          // INCR addressing mode
                m_axi_arvalid <= 1'b1;
            end else if (m_axi_arvalid & m_axi_arready) begin
                m_axi_arlen   <= 8'h0;
                m_axi_arsize  <= 3'h0;
                m_axi_arburst <= 2'h0;
                m_axi_arvalid <= 1'b0;
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // read data channel
    always @(posedge aclk or posedge areset) begin
        if (areset) begin
            has_dc_rd_req_r <= 1'b0;
            has_ic_rd_req_r <= 1'b0;
        end else begin
            if (m_axi_rlast & m_axi_rvalid) begin
                has_dc_rd_req_r <= 1'b0;
                has_ic_rd_req_r <= 1'b0;
            end else begin
                if (has_dc_rd_req)
                    has_dc_rd_req_r <= 1'b1;
                if (has_ic_rd_req)
                    has_ic_rd_req_r <= 1'b1;
            end
        end
    end

    always @(posedge aclk or posedge areset) begin
        if (areset) begin
            dc_dev_rrdy <= 1'b1;
            ic_dev_rrdy <= 1'b1;
        end else begin
            if (m_axi_rlast & m_axi_rvalid) begin
                dc_dev_rrdy <= 1'b1;
                ic_dev_rrdy <= 1'b1;
            end else if (has_dc_rd_req) begin
                dc_dev_rrdy <= 1'b0;
            end else if (has_ic_rd_req) begin
                ic_dev_rrdy <= 1'b0;
            end
        end
    end

    always @(posedge aclk or posedge areset) begin
        if (areset) begin
            dc_dev_rvalid <= 1'b0;
            ic_dev_rvalid <= 1'b0;
        end else begin
            if (dc_dev_rvalid) begin
                dc_dev_rvalid <= 1'b0;
            end else if (ic_dev_rvalid) begin
                ic_dev_rvalid <= 1'b0;
            end else if (m_axi_rlast & m_axi_rvalid) begin
                if (has_dc_rd_req_r)
                    dc_dev_rvalid <= 1'b1;
                else if (has_ic_rd_req_r)
                    ic_dev_rvalid <= 1'b1;
            end
        end
    end

    always @(posedge aclk or posedge areset) begin
        if (areset) begin
            dc_dev_rdata <= 'h0;
            ic_dev_rdata <= 'h0;
        end else if (m_axi_rvalid) begin
            if (has_dc_rd_req_r) begin
`ifdef ENABLE_DCACHE
                dc_dev_rdata <= dc_uncached_rd ? m_axi_rdata : {m_axi_rdata, dc_dev_rdata[`DC_BLK_SIZE-1:32]};
`else
                dc_dev_rdata <= m_axi_rdata;
`endif
            end else if (has_ic_rd_req_r) begin
`ifdef ENABLE_ICACHE
                ic_dev_rdata <= {m_axi_rdata, ic_dev_rdata[`IC_BLK_SIZE-1:32]};
`else
                ic_dev_rdata <= m_axi_rdata;
`endif
            end
        end
    end

    always @(posedge aclk or posedge areset) begin
        m_axi_rready <= areset ? 1'b0 : 1'b1;
    end

endmodule
