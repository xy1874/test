`timescale 1ns / 1ps

module digled (
    input  wire         rst,
    input  wire         clk,
    input  wire [31:0]  disp_data,
    
    output reg  [ 7:0]  dig_en,
    output reg          DN0_A,
    output reg          DN0_B,
    output reg          DN0_C,
    output reg          DN0_D,
    output reg          DN0_E,
    output reg          DN0_F,
    output reg          DN0_G,
    output wire         DN0_DP
);
  
    reg [ 3:0] num_i;
    reg [ 3:0] num;
    reg [15:0] cnt;

    always @(posedge clk) begin
        if (rst)
            num_i <= 4'h7;
        else if (cnt == 16'h0 && num_i == 4'h0)
            num_i <= 4'h7;
        else if (cnt == 16'h0)
            num_i <= num_i - 4'h1;
    end
    
    always @(posedge clk) begin
        if (rst)
            cnt <= 16'h0;
        else if (cnt == 16'h6000)
            cnt <= 16'h0;
        else
            cnt <= cnt + 16'h1;
    end
    
    always @(*) begin
        case (num_i)
            4'h7: num = disp_data[31:28];
            4'h6: num = disp_data[27:24];
            4'h5: num = disp_data[23:20];
            4'h4: num = disp_data[19:16];
            4'h3: num = disp_data[15:12];
            4'h2: num = disp_data[11: 8];
            4'h1: num = disp_data[ 7: 4];
            4'h0: num = disp_data[ 3: 0];
            default: num = 4'h0;
        endcase
    end
    
    always @(*) begin
        case (num_i)
            4'h7: dig_en = 8'b01111111; 
            4'h6: dig_en = 8'b10111111; 
            4'h5: dig_en = 8'b11011111; 
            4'h4: dig_en = 8'b11101111; 
            4'h3: dig_en = 8'b11110111; 
            4'h2: dig_en = 8'b11111011; 
            4'h1: dig_en = 8'b11111101; 
            4'h0: dig_en = 8'b11111110; 
            default: dig_en = 8'h1;
        endcase
    end
    
    always @(*) begin
        case (num)
            4'hF: begin DN0_A=0; DN0_B=1; DN0_C=1; DN0_D=1; DN0_E=0; DN0_F=0; DN0_G=0; end
            4'hE: begin DN0_A=0; DN0_B=1; DN0_C=1; DN0_D=0; DN0_E=0; DN0_F=0; DN0_G=0; end
            4'hD: begin DN0_A=1; DN0_B=0; DN0_C=0; DN0_D=0; DN0_E=0; DN0_F=1; DN0_G=0; end
            4'hC: begin DN0_A=0; DN0_B=1; DN0_C=1; DN0_D=0; DN0_E=0; DN0_F=0; DN0_G=1; end
            4'hB: begin DN0_A=1; DN0_B=1; DN0_C=0; DN0_D=0; DN0_E=0; DN0_F=0; DN0_G=0; end
            4'hA: begin DN0_A=0; DN0_B=0; DN0_C=0; DN0_D=1; DN0_E=0; DN0_F=0; DN0_G=0; end
            4'h9: begin DN0_A=0; DN0_B=0; DN0_C=0; DN0_D=1; DN0_E=1; DN0_F=0; DN0_G=0; end
            4'h8: begin DN0_A=0; DN0_B=0; DN0_C=0; DN0_D=0; DN0_E=0; DN0_F=0; DN0_G=0; end
            4'h7: begin DN0_A=0; DN0_B=0; DN0_C=0; DN0_D=1; DN0_E=1; DN0_F=1; DN0_G=1; end
            4'h6: begin DN0_A=0; DN0_B=1; DN0_C=0; DN0_D=0; DN0_E=0; DN0_F=0; DN0_G=0; end
            4'h5: begin DN0_A=0; DN0_B=1; DN0_C=0; DN0_D=0; DN0_E=1; DN0_F=0; DN0_G=0; end
            4'h4: begin DN0_A=1; DN0_B=0; DN0_C=0; DN0_D=1; DN0_E=1; DN0_F=0; DN0_G=0; end
            4'h3: begin DN0_A=0; DN0_B=0; DN0_C=0; DN0_D=0; DN0_E=1; DN0_F=1; DN0_G=0; end
            4'h2: begin DN0_A=0; DN0_B=0; DN0_C=1; DN0_D=0; DN0_E=0; DN0_F=1; DN0_G=0; end
            4'h1: begin DN0_A=1; DN0_B=0; DN0_C=0; DN0_D=1; DN0_E=1; DN0_F=1; DN0_G=1; end
            4'h0: begin DN0_A=0; DN0_B=0; DN0_C=0; DN0_D=0; DN0_E=0; DN0_F=0; DN0_G=1; end
        endcase
    end

    assign DN0_DP = 1;
    
endmodule
