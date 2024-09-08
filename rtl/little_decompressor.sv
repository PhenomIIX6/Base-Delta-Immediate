module little_decompressor
#(
    parameter WORD_WIDTH    = 32,
    parameter ADDR_WIDTH    = 32,
    parameter RPV4_CODE     = 4'b0000,
    parameter RPV8_CODE     = 4'b0001,
    parameter B8D1_CODE     = 4'b0010,
    parameter B8D2_CODE     = 4'b0011,
    parameter B8D4_CODE     = 4'b0100,
    parameter B4D1_CODE     = 4'b0101,
    parameter B4D2_CODE     = 4'b0110,
    parameter B2D1_CODE     = 4'b0111,
    parameter NO_COMPR_CODE = 4'b1111
)
(
    input  logic [8 * WORD_WIDTH-1:0]       compressed_data,
    input  logic [3:0]                      compressed_mode,
    input  logic [15:0]                     base_one_hot,

    output logic [8 * WORD_WIDTH-1:0]       decompressed_data
);
    logic [63:0]    b8d1_base; 
    logic [63:0]    b8d2_base;
    logic [63:0]    b8d4_base;
    logic [31:0]    b4d1_base;
    logic [31:0]    b4d2_base;
    logic [15:0]    b2d1_base;
    logic [31:0]    rpv4_base;
    logic [63:0]    rpv8_base;

    logic [7:0]     b8d1_segments [3:0]; 
    logic [15:0]    b8d2_segments [3:0];
    logic [31:0]    b8d4_segments [3:0];
    logic [7:0]     b4d1_segments [7:0];
    logic [15:0]    b4d2_segments [7:0];
    logic [7:0]     b2d1_segments [31:0];

    always_comb
    begin
        for(int i = 0; i < 4; i++) begin
            b8d1_segments[i] = compressed_data[i*8+:8];
            b8d2_segments[i] = compressed_data[i*16+:16];
            b8d4_segments[i] = compressed_data[i*32+:32];
        end
        for(int i = 0; i < 8; i++) begin
            b4d1_segments[i] = compressed_data[i*8+:8];
            b4d2_segments[i] = compressed_data[i*16+:16];
        end
        for(int i = 0; i < 16; i++) begin
            b2d1_segments[i] = compressed_data[i*8+:8];
        end
    end

    assign b8d1_base = compressed_data[(12 * 8)-1: 4 * 8];
    assign b8d2_base = compressed_data[(16 * 8)-1: 8 * 8];
    assign b8d4_base = compressed_data[(24 * 8)-1: 16 * 8];
    assign b4d1_base = compressed_data[(12 * 8)-1: 8 * 8];
    assign b4d2_base = compressed_data[(20 * 8)-1: 16 * 8];
    assign b2d1_base = compressed_data[(14 * 8)-1: 12 * 8];
    assign rpv4_base = compressed_data[31:0];
    assign rpv8_base = compressed_data[63:0];

    always_comb
    begin
        decompressed_data = 'b0;
        case(compressed_mode)
            RPV4_CODE: begin
                for(int i = 0; i < 8; i++) begin
                    decompressed_data[i*32+:32] = rpv4_base;
                end
            end
            RPV8_CODE: begin
                for(int i = 0; i < 4; i++) begin
                    decompressed_data[i*64+:64] = rpv8_base;
                end
            end
            B8D1_CODE: begin
                for(int i = 0; i < 4; i++) begin
                    decompressed_data[i*64+:64] = base_one_hot[i] ? (b8d1_base + b8d1_segments[i]) : b8d1_segments[i];
                end
            end
            B8D2_CODE: begin
                for(int i = 0; i < 4; i++) begin
                    decompressed_data[i*64+:64] = base_one_hot[i] ? (b8d2_base + b8d2_segments[i]) : b8d2_segments[i];
                end
            end
            B8D4_CODE: begin
                for(int i = 0; i < 4; i++) begin
                    decompressed_data[i*64+:64] = base_one_hot[i] ? (b8d4_base + b8d4_segments[i]) : b8d4_segments[i];
                end
            end
            B4D1_CODE: begin
                for(int i = 0; i < 8; i++) begin
                    decompressed_data[i*32+:32] = base_one_hot[i] ? (b4d1_base + b4d1_segments[i]) : b4d1_segments[i];
                end
            end
            B4D2_CODE: begin
                for(int i = 0; i < 8; i++) begin
                    decompressed_data[i*32+:32] = base_one_hot[i] ? (b4d2_base + b4d2_segments[i]) : b4d2_segments[i];
                end
            end 
            B2D1_CODE: begin
                for(int i = 0; i < 16; i++) begin
                    decompressed_data[i*16+:16] = base_one_hot[i] ? (b2d1_base + b2d1_segments[i]) : b2d1_segments[i];
                end
            end
            NO_COMPR_CODE: decompressed_data = compressed_data;
        endcase
    end

endmodule