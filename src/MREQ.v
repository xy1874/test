`timescale 1ns / 1ps

`include "defines.vh"

module MREQ (
    input  wire [31:0]  ram_addr,

    input  wire [ 2:0]  ram_rop,
    output reg  [ 3:0]  da_ren,
    output wire [31:0]  da_addr,

    input  wire [ 3:0]  ram_wop,
    input  wire [31:0]  ram_wdata,
    output reg  [ 3:0]  da_wen,
    output reg  [31:0]  da_wdata
);

    wire [1:0] offset = ram_addr[1:0];

    assign da_addr = ram_addr;

    always @(*) begin
        // default value
        da_wen   = 4'h0;
        da_wdata = ram_wdata;

        case (ram_wop)
            `RAM_WE_B: begin                            // sb
                if (offset == 2'h3) begin
                    da_wen   = ram_wop << 3;
                    da_wdata = ram_wdata << 24;
                end else if (offset == 2'h2) begin
                    da_wen   = ram_wop << 2;
                    da_wdata = ram_wdata << 16;
                end else if (offset == 2'h1) begin
                    da_wen   = ram_wop << 1;
                    da_wdata = ram_wdata << 8;
                end else if (offset == 2'h0) begin
                    da_wen   = ram_wop;
                end
            end
            `RAM_WE_H:                                  // sh
                if (offset == 2'h2) begin
                    da_wen   = ram_wop << 2;
                    da_wdata = ram_wdata << 16;
                end else if (offset == 2'h0) begin
                    da_wen   = ram_wop;
                end
            `RAM_WE_W:                                  // sw
                if (offset == 2'h0) begin
                    da_wen   = ram_wop;
                end
        endcase
    end

    always @(*) begin
        if (ram_rop != `RAM_EXT_N) begin
            case (ram_rop)
                `RAM_EXT_B : da_ren = 4'hF;                                                 // lb
                `RAM_EXT_BU: da_ren = 4'hF;                                                 // lbu
                `RAM_EXT_H : da_ren = (offset == 2'h0 || offset == 2'h2) ? 4'hF : 4'h0;     // lh
                `RAM_EXT_HU: da_ren = (offset == 2'h0 || offset == 2'h2) ? 4'hF : 4'h0;     // lhu
                default    : da_ren = (offset == 2'h0) ? 4'hF : 4'h0;                       // lw
            endcase
        end else
            da_ren = 4'h0;
    end

endmodule
