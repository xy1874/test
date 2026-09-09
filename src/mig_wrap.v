`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/27 09:35:08
// Design Name: 
// Module Name: mig_wrap
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mig_wrap (
    input  wire         aclk,
    input  wire         aresetn,
    input  wire [31:0]  s_axi_awaddr,
    input  wire [ 7:0]  s_axi_awlen,
    input  wire [ 2:0]  s_axi_awsize,
    input  wire [ 1:0]  s_axi_awburst,
    input  wire [ 3:0]  s_axi_awcache,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,
    input  wire [31:0]  s_axi_wdata,
    input  wire [ 3:0]  s_axi_wstrb,
    input  wire         s_axi_wlast,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,
    output wire [ 1:0]  s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,
    input  wire [31:0]  s_axi_araddr,
    input  wire [ 7:0]  s_axi_arlen,
    input  wire [ 2:0]  s_axi_arsize,
    input  wire [ 1:0]  s_axi_arburst,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,
    output wire [31:0]  s_axi_rdata,
    output wire [ 1:0]  s_axi_rresp,
    output wire         s_axi_rlast,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,

    input  wire         mig_sys_clk,
    output reg          ddr_init_done,
    output wire [14:0]  ddr3_addr,
    output wire [ 2:0]  ddr3_ba,
    output wire         ddr3_cas_n,
    output wire [ 0:0]  ddr3_ck_p,
    output wire [ 0:0]  ddr3_ck_n,
    output wire [ 0:0]  ddr3_cke,
    output wire         ddr3_ras_n,
    output wire         ddr3_we_n,
    inout  wire [15:0]  ddr3_dq,
    inout  wire [ 1:0]  ddr3_dqs_n,
    inout  wire [ 1:0]  ddr3_dqs_p,
    output wire         ddr3_reset_n,
    output wire [ 0:0]  ddr3_cs_n,
    output wire [ 1:0]  ddr3_dm,
    output wire [ 0:0]  ddr3_odt
);

    wire        ui_clk;
    wire        ui_rst;
    wire [ 3:0] mig_awid;
    wire [28:0] mig_awaddr;
    wire [ 7:0] mig_awlen;
    wire [ 2:0] mig_awsize;
    wire [ 1:0] mig_awburst;
    wire [ 0:0] mig_awlock;
    wire [ 3:0] mig_awcache;
    wire [ 2:0] mig_awprot;
    wire [ 3:0] mig_awqos;
    wire        mig_awvalid;
    wire        mig_awready;
    // Slave Interface Write Data Ports
    wire [31:0] mig_wdata;
    wire [ 3:0] mig_wstrb;
    wire        mig_wlast;
    wire        mig_wvalid;
    wire        mig_wready;
    // Slave Interface Write Response Ports
    wire        mig_bready;
    wire [ 3:0] mig_bid;
    wire [ 1:0] mig_bresp;
    wire        mig_bvalid;
    // Slave Interface Read Address Ports
    wire [ 3:0] mig_arid;
    wire [28:0] mig_araddr;
    wire [ 7:0] mig_arlen;
    wire [ 2:0] mig_arsize;
    wire [ 1:0] mig_arburst;
    wire [ 0:0] mig_arlock;
    wire [ 3:0] mig_arcache;
    wire [ 2:0] mig_arprot;
    wire [ 3:0] mig_arqos;
    wire        mig_arvalid;
    wire        mig_arready;
    // Slave Interface Read Data Ports
    wire        mig_rready;
    wire [ 3:0] mig_rid;
    wire [31:0] mig_rdata;
    wire [ 1:0] mig_rresp;
    wire        mig_rlast;
    wire        mig_rvalid;

    reg         aresetn_r;
    reg         mig_rstn;

    wire        init_calib_complete;
    reg         init_calib_complete_r;

    always @(posedge mig_sys_clk or negedge aresetn) begin
        aresetn_r <= !aresetn ? 1'b0 : 1'b1;
        mig_rstn  <= !aresetn ? 1'b0 : aresetn_r;
    end
    
    always @(posedge aclk or negedge aresetn) begin
        init_calib_complete_r <= !aresetn ? 1'b0 : init_calib_complete;
        ddr_init_done         <= !aresetn ? 1'b0 : init_calib_complete_r;
    end

    axi_interconnect_0 U_axi_con (
        .INTERCONNECT_ACLK      (aclk),           // input wire INTERCONNECT_ACLK
        .INTERCONNECT_ARESETN   (aresetn),          // input wire INTERCONNECT_ARESETN
        .S00_AXI_ARESET_OUT_N   (),                 // output wire S00_AXI_ARESET_OUT_N
        .S00_AXI_ACLK           (aclk),                  // input wire S00_AXI_ACLK
        .S00_AXI_AWID           (1'b0),                  // input wire [0 : 0] S00_AXI_AWID
        .S00_AXI_AWADDR         (s_axi_awaddr),              // input wire [31 : 0] S00_AXI_AWADDR
        .S00_AXI_AWLEN          (s_axi_awlen),                // input wire [7 : 0] S00_AXI_AWLEN
        .S00_AXI_AWSIZE         (s_axi_awsize),              // input wire [2 : 0] S00_AXI_AWSIZE
        .S00_AXI_AWBURST        (s_axi_awburst),            // input wire [1 : 0] S00_AXI_AWBURST
        .S00_AXI_AWLOCK         (1'b0),              // input wire S00_AXI_AWLOCK
        .S00_AXI_AWCACHE        (4'h0),            // input wire [3 : 0] S00_AXI_AWCACHE
        .S00_AXI_AWPROT         (3'h0),              // input wire [2 : 0] S00_AXI_AWPROT
        .S00_AXI_AWQOS          (4'h0),                // input wire [3 : 0] S00_AXI_AWQOS
        .S00_AXI_AWVALID        (s_axi_awvalid),            // input wire S00_AXI_AWVALID
        .S00_AXI_AWREADY        (s_axi_awready),            // output wire S00_AXI_AWREADY
        .S00_AXI_WDATA          (s_axi_wdata),                // input wire [31 : 0] S00_AXI_WDATA
        .S00_AXI_WSTRB          (s_axi_wstrb),                // input wire [3 : 0] S00_AXI_WSTRB
        .S00_AXI_WLAST          (s_axi_wlast),                // input wire S00_AXI_WLAST
        .S00_AXI_WVALID         (s_axi_wvalid),              // input wire S00_AXI_WVALID
        .S00_AXI_WREADY         (s_axi_wready),              // output wire S00_AXI_WREADY
        .S00_AXI_BID            (),                    // output wire [0 : 0] S00_AXI_BID
        .S00_AXI_BRESP          (s_axi_bresp),                // output wire [1 : 0] S00_AXI_BRESP
        .S00_AXI_BVALID         (s_axi_bvalid),              // output wire S00_AXI_BVALID
        .S00_AXI_BREADY         (s_axi_bready),              // input wire S00_AXI_BREADY
        .S00_AXI_ARID           (1'b1),                  // input wire [0 : 0] S00_AXI_ARID
        .S00_AXI_ARADDR         (s_axi_araddr),              // input wire [31 : 0] S00_AXI_ARADDR
        .S00_AXI_ARLEN          (s_axi_arlen),                // input wire [7 : 0] S00_AXI_ARLEN
        .S00_AXI_ARSIZE         (s_axi_arsize),              // input wire [2 : 0] S00_AXI_ARSIZE
        .S00_AXI_ARBURST        (s_axi_arburst),            // input wire [1 : 0] S00_AXI_ARBURST
        .S00_AXI_ARLOCK         (1'b0),              // input wire S00_AXI_ARLOCK
        .S00_AXI_ARCACHE        (4'h0),            // input wire [3 : 0] S00_AXI_ARCACHE
        .S00_AXI_ARPROT         (3'h0),              // input wire [2 : 0] S00_AXI_ARPROT
        .S00_AXI_ARQOS          (4'h0),                // input wire [3 : 0] S00_AXI_ARQOS
        .S00_AXI_ARVALID        (s_axi_arvalid),            // input wire S00_AXI_ARVALID
        .S00_AXI_ARREADY        (s_axi_arready),            // output wire S00_AXI_ARREADY
        .S00_AXI_RID            (),                    // output wire [0 : 0] S00_AXI_RID
        .S00_AXI_RDATA          (s_axi_rdata),                // output wire [31 : 0] S00_AXI_RDATA
        .S00_AXI_RRESP          (s_axi_rresp),                // output wire [1 : 0] S00_AXI_RRESP
        .S00_AXI_RLAST          (s_axi_rlast),                // output wire S00_AXI_RLAST
        .S00_AXI_RVALID         (s_axi_rvalid),              // output wire S00_AXI_RVALID
        .S00_AXI_RREADY         (s_axi_rready),              // input wire S00_AXI_RREADY
        // .M00_AXI_ARESET_OUT_N(M00_AXI_ARESET_OUT_N),  // output wire M00_AXI_ARESET_OUT_N
        .M00_AXI_ACLK           (ui_clk),                  // input wire M00_AXI_ACLK
        .M00_AXI_AWID           (mig_awid),                  // output wire [3 : 0] M00_AXI_AWID
        .M00_AXI_AWADDR         (mig_awaddr),              // output wire [31 : 0] M00_AXI_AWADDR
        .M00_AXI_AWLEN          (mig_awlen),                // output wire [7 : 0] M00_AXI_AWLEN
        .M00_AXI_AWSIZE         (mig_awsize),              // output wire [2 : 0] M00_AXI_AWSIZE
        .M00_AXI_AWBURST        (mig_awburst),            // output wire [1 : 0] M00_AXI_AWBURST
        .M00_AXI_AWLOCK         (mig_awlock),              // output wire M00_AXI_AWLOCK
        .M00_AXI_AWCACHE        (mig_awcache),            // output wire [3 : 0] M00_AXI_AWCACHE
        .M00_AXI_AWPROT         (mig_awprot),              // output wire [2 : 0] M00_AXI_AWPROT
        .M00_AXI_AWQOS          (mig_awqos),                // output wire [3 : 0] M00_AXI_AWQOS
        .M00_AXI_AWVALID        (mig_awvalid),            // output wire M00_AXI_AWVALID
        .M00_AXI_AWREADY        (mig_awready),            // input wire M00_AXI_AWREADY
        .M00_AXI_WDATA          (mig_wdata),                // output wire [31 : 0] M00_AXI_WDATA
        .M00_AXI_WSTRB          (mig_wstrb),                // output wire [3 : 0] M00_AXI_WSTRB
        .M00_AXI_WLAST          (mig_wlast),                // output wire M00_AXI_WLAST
        .M00_AXI_WVALID         (mig_wvalid),              // output wire M00_AXI_WVALID
        .M00_AXI_WREADY         (mig_wready),              // input wire M00_AXI_WREADY
        .M00_AXI_BID            (mig_bid),                    // input wire [3 : 0] M00_AXI_BID
        .M00_AXI_BRESP          (mig_bresp),                // input wire [1 : 0] M00_AXI_BRESP
        .M00_AXI_BVALID         (mig_bvalid),              // input wire M00_AXI_BVALID
        .M00_AXI_BREADY         (mig_bready),              // output wire M00_AXI_BREADY
        .M00_AXI_ARID           (mig_arid),                  // output wire [3 : 0] M00_AXI_ARID
        .M00_AXI_ARADDR         (mig_araddr),              // output wire [31 : 0] M00_AXI_ARADDR
        .M00_AXI_ARLEN          (mig_arlen),                // output wire [7 : 0] M00_AXI_ARLEN
        .M00_AXI_ARSIZE         (mig_arsize),              // output wire [2 : 0] M00_AXI_ARSIZE
        .M00_AXI_ARBURST        (mig_arburst),            // output wire [1 : 0] M00_AXI_ARBURST
        .M00_AXI_ARLOCK         (mig_arlock),              // output wire M00_AXI_ARLOCK
        .M00_AXI_ARCACHE        (mig_arcache),            // output wire [3 : 0] M00_AXI_ARCACHE
        .M00_AXI_ARPROT         (mig_arprot),              // output wire [2 : 0] M00_AXI_ARPROT
        .M00_AXI_ARQOS          (mig_arqos),                // output wire [3 : 0] M00_AXI_ARQOS
        .M00_AXI_ARVALID        (mig_arvalid),            // output wire M00_AXI_ARVALID
        .M00_AXI_ARREADY        (mig_arready),            // input wire M00_AXI_ARREADY
        .M00_AXI_RID            (mig_rid),                    // input wire [3 : 0] M00_AXI_RID
        .M00_AXI_RDATA          (mig_rdata),                // input wire [31 : 0] M00_AXI_RDATA
        .M00_AXI_RRESP          (mig_rresp),                // input wire [1 : 0] M00_AXI_RRESP
        .M00_AXI_RLAST          (mig_rlast),                // input wire M00_AXI_RLAST
        .M00_AXI_RVALID         (mig_rvalid),              // input wire M00_AXI_RVALID
        .M00_AXI_RREADY         (mig_rready)              // output wire M00_AXI_RREADY
    );

    mig_7series_0 U_mig (
       .sys_clk_i               (mig_sys_clk),
       .sys_rst                 (mig_rstn),         // Active Low

        // Application interface ports
       .ui_clk                  (ui_clk),
       .ui_clk_sync_rst         (ui_rst),
    //    .mmcm_locked             (mmcm_locked),
       .aresetn                 (!ui_rst),
       .app_sr_req              (1'b0),
       .app_ref_req             (1'b0),
       .app_zq_req              (1'b0),
    //    .app_sr_active           (app_sr_active),
    //    .app_ref_ack             (app_ref_ack),
    //    .app_zq_ack              (app_zq_ack),
        // Slave Interface Write Address Ports
       .s_axi_awid              (mig_awid),
       .s_axi_awaddr            (mig_awaddr),
       .s_axi_awlen             (mig_awlen),
       .s_axi_awsize            (mig_awsize),
       .s_axi_awburst           (mig_awburst),
       .s_axi_awlock            (mig_awlock),
       .s_axi_awcache           (mig_awcache),
       .s_axi_awprot            (mig_awprot),
       .s_axi_awqos             (mig_awqos),
       .s_axi_awvalid           (mig_awvalid),
       .s_axi_awready           (mig_awready),
        // Slave Interface Write Data Ports
       .s_axi_wdata             (mig_wdata),
       .s_axi_wstrb             (mig_wstrb),
       .s_axi_wlast             (mig_wlast),
       .s_axi_wvalid            (mig_wvalid),
       .s_axi_wready            (mig_wready),
        // Slave Interface Write Response Ports
       .s_axi_bid               (mig_bid),
       .s_axi_bresp             (mig_bresp),
       .s_axi_bvalid            (mig_bvalid),
       .s_axi_bready            (mig_bready),
        // Slave Interface Read Address Ports
       .s_axi_arid              (mig_arid),
       .s_axi_araddr            (mig_araddr),
       .s_axi_arlen             (mig_arlen),
       .s_axi_arsize            (mig_arsize),
       .s_axi_arburst           (mig_arburst),
       .s_axi_arlock            (mig_arlock),
       .s_axi_arcache           (mig_arcache),
       .s_axi_arprot            (mig_arprot),
       .s_axi_arqos             (mig_arqos),
       .s_axi_arvalid           (mig_arvalid),
       .s_axi_arready           (mig_arready),
        // Slave Interface Read Data Ports
       .s_axi_rid               (mig_rid),
       .s_axi_rdata             (mig_rdata),
       .s_axi_rresp             (mig_rresp),
       .s_axi_rlast             (mig_rlast),
       .s_axi_rvalid            (mig_rvalid),
       .s_axi_rready            (mig_rready),

        // Memory interface ports
       .init_calib_complete     (init_calib_complete),
       .ddr3_addr               (ddr3_addr),
       .ddr3_ba                 (ddr3_ba),
       .ddr3_cas_n              (ddr3_cas_n),
       .ddr3_ck_n               (ddr3_ck_n),
       .ddr3_ck_p               (ddr3_ck_p),
       .ddr3_cke                (ddr3_cke),
       .ddr3_ras_n              (ddr3_ras_n),
       .ddr3_we_n               (ddr3_we_n),
       .ddr3_dq                 (ddr3_dq),
       .ddr3_dqs_n              (ddr3_dqs_n),
       .ddr3_dqs_p              (ddr3_dqs_p),
       .ddr3_reset_n            (ddr3_reset_n),
       .ddr3_cs_n               (ddr3_cs_n),
       .ddr3_dm                 (ddr3_dm),
       .ddr3_odt                (ddr3_odt)
    );

endmodule
