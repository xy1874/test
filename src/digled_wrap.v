`timescale 1ns / 1ps

module digled_wrap(
    input  wire         aclk,
    input  wire         aresetn,
    input  wire [31:0]  s_axi_awaddr,
    input  wire [ 7:0]  s_axi_awlen,
    input  wire [ 2:0]  s_axi_awsize,
    input  wire [ 1:0]  s_axi_awburst,
    input  wire [ 0:0]  s_axi_awlock,
    input  wire [ 3:0]  s_axi_awcache,
    input  wire [ 2:0]  s_axi_awprot,
    input  wire [ 3:0]  s_axi_awregion,
    input  wire [ 3:0]  s_axi_awqos,
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
    input  wire [ 0:0]  s_axi_arlock,
    input  wire [ 3:0]  s_axi_arcache,
    input  wire [ 2:0]  s_axi_arprot,
    input  wire [ 3:0]  s_axi_arregion,
    input  wire [ 3:0]  s_axi_arqos,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,
    output wire [31:0]  s_axi_rdata,
    output wire [ 1:0]  s_axi_rresp,
    output wire         s_axi_rlast,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,

    output wire [ 7:0]  dig_en,
    output wire [ 7:0]  dig_seg
);

    wire [31:0] digled_awaddr;
    wire        digled_awready;
    wire        digled_awvalid;
    wire [31:0] digled_wdata;
    wire        digled_wready;
    wire [ 3:0] digled_wstrb;
    wire        digled_wvalid;
    wire        digled_bready;
    wire [ 1:0] digled_bresp;
    wire        digled_bvalid;
    wire [31:0] digled_araddr;
    wire        digled_arready;
    wire        digled_arvalid;
    wire [31:0] digled_rdata;
    wire        digled_rready;
    wire [ 1:0] digled_rresp;
    wire        digled_rvalid;

    wire [31:0] display_data;

    axi_protocol_converter_0 U_digled_converter (
        .aclk               (aclk),
        .aresetn            (aresetn),
        .s_axi_awaddr       (s_axi_awaddr),
        .s_axi_awlen        (s_axi_awlen),
        .s_axi_awsize       (s_axi_awsize),
        .s_axi_awburst      (s_axi_awburst),
        .s_axi_awlock       (s_axi_awlock),
        .s_axi_awcache      (s_axi_awcache),
        .s_axi_awprot       (s_axi_awprot),
        .s_axi_awregion     (s_axi_awregion),
        .s_axi_awqos        (s_axi_awqos),
        .s_axi_awvalid      (s_axi_awvalid),
        .s_axi_awready      (s_axi_awready),
        .s_axi_wdata        (s_axi_wdata),
        .s_axi_wstrb        (s_axi_wstrb),
        .s_axi_wlast        (s_axi_wlast),
        .s_axi_wvalid       (s_axi_wvalid),
        .s_axi_wready       (s_axi_wready),
        .s_axi_bresp        (s_axi_bresp),
        .s_axi_bvalid       (s_axi_bvalid),
        .s_axi_bready       (s_axi_bready),
        .s_axi_araddr       (s_axi_araddr),
        .s_axi_arlen        (s_axi_arlen),
        .s_axi_arsize       (s_axi_arsize),
        .s_axi_arburst      (s_axi_arburst),
        .s_axi_arlock       (s_axi_arlock),
        .s_axi_arcache      (s_axi_arcache),
        .s_axi_arprot       (s_axi_arprot),
        .s_axi_arregion     (s_axi_arregion),
        .s_axi_arqos        (s_axi_arqos),
        .s_axi_arvalid      (s_axi_arvalid),
        .s_axi_arready      (s_axi_arready),
        .s_axi_rdata        (s_axi_rdata),
        .s_axi_rresp        (s_axi_rresp),
        .s_axi_rlast        (s_axi_rlast),
        .s_axi_rvalid       (s_axi_rvalid),
        .s_axi_rready       (s_axi_rready),
        .m_axi_awaddr       (digled_awaddr),
        .m_axi_awvalid      (digled_awvalid),
        .m_axi_awready      (digled_awready),
        .m_axi_wdata        (digled_wdata),
        .m_axi_wstrb        (digled_wstrb),
        .m_axi_wvalid       (digled_wvalid),
        .m_axi_wready       (digled_wready),
        .m_axi_bresp        (digled_bresp),
        .m_axi_bvalid       (digled_bvalid),
        .m_axi_bready       (digled_bready),
        .m_axi_araddr       (digled_araddr),
        .m_axi_arvalid      (digled_arvalid),
        .m_axi_arready      (digled_arready),
        .m_axi_rdata        (digled_rdata),
        .m_axi_rresp        (digled_rresp),
        .m_axi_rvalid       (digled_rvalid),
        .m_axi_rready       (digled_rready)
    );

    axi_gpio_1 U_digled_data (
        .s_axi_aclk         (aclk),
        .s_axi_aresetn      (aresetn),
        .s_axi_awaddr       (digled_awaddr),
        .s_axi_awready      (digled_awready),
        .s_axi_awvalid      (digled_awvalid),
        .s_axi_wdata        (digled_wdata),
        .s_axi_wready       (digled_wready),
        .s_axi_wstrb        (digled_wstrb),
        .s_axi_wvalid       (digled_wvalid),
        .s_axi_bready       (digled_bready),
        .s_axi_bresp        (digled_bresp),
        .s_axi_bvalid       (digled_bvalid),
        .s_axi_araddr       (digled_araddr),
        .s_axi_arready      (digled_arready),
        .s_axi_arvalid      (digled_arvalid),
        .s_axi_rdata        (digled_rdata),
        .s_axi_rready       (digled_rready),
        .s_axi_rresp        (digled_rresp),
        .s_axi_rvalid       (digled_rvalid),

        .gpio_io_o          (display_data)
    );

    digled U_digled (
        .rst        (!aresetn),
        .clk        (aclk),
        .disp_data  (display_data),
        
        .dig_en     (dig_en),
        .DN0_A      (dig_seg[7]),
        .DN0_B      (dig_seg[6]),
        .DN0_C      (dig_seg[5]),
        .DN0_D      (dig_seg[4]),
        .DN0_E      (dig_seg[3]),
        .DN0_F      (dig_seg[2]),
        .DN0_G      (dig_seg[1]),
        .DN0_DP     (dig_seg[0])
    );

endmodule
