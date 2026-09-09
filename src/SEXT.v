`timescale 1ns / 1ps

module SEXT (
    input  wire [ 2:0]  op,
    input  wire [24:0]  imm,
    output reg  [31:0]  ext
);
    
    always @(*) begin
        case (op)
            `EXT_I : ext = {{20{imm[24]}}, imm[24:13]};
            `EXT_S : ext = {{20{imm[24]}}, imm[24:18], imm[4:0]};
            `EXT_B : ext = {{19{imm[24]}}, imm[24], imm[0], imm[23:18], imm[4:1], 1'b0};
            `EXT_U : ext = {imm[24:5], 12'h0};
            `EXT_J : ext = {{11{imm[24]}}, imm[24], imm[12:5], imm[13], imm[23:14], 1'b0};
            default: ext = 32'h0;
        endcase
    end
    
endmodule
