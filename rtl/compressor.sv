module little_compressor
#(
    parameter WORD_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
)
(
    input  logic [8 * WORD_WIDTH-1:0]       cacheline,

    output logic [8 * WORD_WIDTH-1:0]       compressed_data,
    output logic [3:0]                      compressed_mode,
    output logic [15:0]                     base_one_hot
);

    logic b8d1_compressible; 
    logic b8d2_compressible;
    logic b8d4_compressible;
    logic b4d1_compressible;
    logic b4d2_compressible;
    logic b2d1_compressible;
    logic reapeted_values_4_compressible;
    logic reapeted_values_8_compressible;

    logic [63:0] b8_segments [3:0];
    logic [31:0] b4_segments [7:0];
    logic [15:0] b2_segments [15:0];

    logic [3:0]  b8d1_base_one_hot;
    logic [3:0]  b8d2_base_one_hot;
    logic [3:0]  b8d4_base_one_hot;
    logic [7:0]  b4d1_base_one_hot;
    logic [7:0]  b4d2_base_one_hot;
    logic [15:0] b2d1_base_one_hot;

    logic [8 * WORD_WIDTH - 1:0] compressed_segments;
    
    // get segments
    always_comb
    begin
        for(int i = 0; i < 4; i++) begin
            b8_segments[i] = cacheline[(i*64)+:63]; 
        end
        for(int i = 0; i < 8; i++) begin
            b4_segments[i] = cacheline[(i*32)+:31]; 
        end
        for(int i = 0; i < 8; i++) begin
            b2_segments[i] = cacheline[(i*16)+:15]; 
        end
    end

    // compressible check
    always_comb
    begin
        b8d1_compressible = 1;
        b8d2_compressible = 1;
        b8d4_compressible = 1;
        b4d1_compressible = 1;
        b4d2_compressible = 1;
        b2d1_compressible = 1;
        repeated_values_8_compressible = 1;
        repeated_values_4_compressible = 1;
        for(int i = 0; i < 4; i++) begin
            if(b8_segments[i][63:8] == 0) b8d1_base_one_hot[i] = 0;
            else if(b8_segments[i][63:8] == b8_segments[0][63:8]) b8d1_base_one_hot[i] = 1;
            else b8d1_compressible = 0;
        end
        for(int i = 0; i < 4; i++) begin
            if(b8_segments[i][63:16] == 0) b8d1_base_one_hot[i] = 0;
            else if(b8_segments[i][63:16] == b8_segments[0][63:16]) b8d2_base_one_hot[i] = 1;
            else b8d2_compressible = 0;
        end
        for(int i = 0; i < 4; i++) begin
            if(b8_segments[i][63:32] == 0) b8d4_base_one_hot[i] = 0;
            else if(b8_segments[i][63:32] == b8_segments[0][63:32]) b8d4_base_one_hot[i] = 1;
            else b8d4_compressible = 0;
        end
        for(int i = 0; i < 8; i++) begin
            if(b4_segments[i][31:8] == 0) b4d1_base_one_hot[i] = 0;
            else if(b4_segments[i][31:8] == b4_segments[0][31:8]) b4d1_base_one_hot[i] = 1;
            else b4d1_compressible = 0;
        end
        for(int i = 0; i < 8; i++) begin
            if(b4_segments[i][31:16] == 0) b4d2_base_one_hot[i] = 0;
            else if(b4_segments[i][31:16] == b4_segments[0][31:16]) b4d2_base_one_hot[i] = 1;
            else b4d2_compressible = 0;
        end
        for(int i = 0; i < 16; i++) begin
            if(b2_segments[i][15:8] == 0) b2d1_base_one_hot[i] = 0;
            else if(b2_segments[i][15:8] == b2_segments[0][15:8]) b2d1_base_one_hot[i] = 1;
            else b2d1_compressible = 0;
        end
        for(int i = 0; i < 4; i++) begin
            if(!(b8_segments[i] == b8_segments[0])) repeated_values_8_compressible = 0; 
        end
        for(int i = 0; i < 8; i++) begin
            if(!(b4_segments[i] == b4_segments[0])) repeated_values_4_compressible = 0;
        end
        end

    // compressed mode with priority
    always_comb 
    begin
        compressed_mode = 'b0;
        if      (repeated_values_4_compressible) compressed_mode = RPV4_CODE;
        else if (repeated_values_8_compressible) compressed_mode = RPV8_CODE;
        else if (b8d1_compressible             ) compressed_mode = B8D1_CODE;
        else if (b4d1_compressible             ) compressed_mode = B4D1_CODE;
        else if (b8d2_compressible             ) compressed_mode = B8D2_CODE;
        else if (b2d1_compressible             ) compressed_mode = B2D1_CODE;
        else if (b4d2_compressible             ) compressed_mode = B4D2_CODE;
        else if (b8d4_compressible             ) compressed_mode = B8D4_CODE;
        else                                     compressed_mode = NO_COMPR_CODE;
    end

    // segments compress
    always_comb
    begin
        compressed_segments = 'b0;
        if      (repeated_values_4_compressible)            compressed_segments = 0;
        else if (repeated_values_8_compressible)            compressed_segments = 0;
        else if (b8d1_compressible             ) begin
            for(int i = 0; i < 4; i++) begin
                if(!b8d1_base_one_hot[i])                   compressed_segments[(i*8)+:7] = b8_segments[i][7:0];
                else if(b8_segments[i] >= b8_segments[0])   compressed_segments[(i*8)+:7] = b8_segments[i] - b8_segments[0];
                else                                        compressed_segments[(i*8)+:7] = b8_segments[0] - b8_segments[i];
            end
        end
        else if (b4d1_compressible             ) begin
            for(int i = 0; i < 8; i++) begin
                if(!b4d1_base_one_hot[i])                   compressed_segments[(i*8)+:7] = b4_segments[i][7:0];
                else if(b4_segments[i] >= b4_segments[0])   compressed_segments[(i*8)+:7] = b4_segments[i] - b4_segments[0];
                else                                        compressed_segments[(i*8)+:7] = b4_segments[0] - b4_segments[i];
            end
        end
        else if (b8d2_compressible             ) begin
            for(int i = 0; i < 4; i++) begin
                if(!b8d2_base_one_hot[i])                   compressed_segments[(i*16)+:15] = b8_segments[i][15:0];
                else if(b8_segments[i] >= b8_segments[0])   compressed_segments[(i*16)+:15] = b8_segments[i] - b8_segments[0];
                else                                        compressed_segments[(i*16)+:15] = b8_segments[0] - b8_segments[i];
            end
        end
        else if (b2d1_compressible             ) begin
            for(int i = 0; i < 16; i++) begin
                if(!b2d1_base_one_hot[i])                   compressed_segments[(i*8)+:7] = b2_segments[i][7:0];
                else if(b2_segments[i] >= b2_segments[0])   compressed_segments[(i*8)+:7] = b2_segments[i] - b2_segments[0];
                else                                        compressed_segments[(i*8)+:7] = b2_segments[0] - b2_segments[i];
            end
        end 
        else if (b4d2_compressible             ) begin
            for(int i = 0; i < 8; i++) begin
                if(!b4d2_base_one_hot[i])                   compressed_segments[(i*16)+:15] = b4_segments[i][15:0];
                else if(b4_segments[i] >= b4_segments[0])   compressed_segments[(i*16)+:15] = b4_segments[i] - b4_segments[0];
                else                                        compressed_segments[(i*16)+:15] = b4_segments[0] - b4_segments[i];
            end
        end
        else if (b8d4_compressible             ) begin
            for(int i = 0; i < 4; i++) begin
                if(!b8d4_base_one_hot[i])                   compressed_segments[(i*32)+:31] = b8_segments[i][31:0];
                else if(b8_segments[i] >= b8_segments[0])   compressed_segments[(i*32)+:31] = b8_segments[i] - b8_segments[0];
                else                                        compressed_segments[(i*32)+:31] = b8_segments[0] - b8_segments[i];
            end
        end                                     
    end

    // compressed data out
    always_comb 
    begin
        compressed_data = 'b0;
        if      (repeated_values_4_compressible) compressed_data[(4 * 8)-1:0]   = b4_segments[0];
        else if (repeated_values_8_compressible) compressed_data[(8 * 8)-1:0]   = b8_segments[0];
        else if (b8d1_compressible             ) compressed_data[(12 * 8)-1:0]  = {b8_segments[0], compressed_segments};
        else if (b4d1_compressible             ) compressed_data[(12 * 8)-1:0]  = {b4_segments[0], compressed_segments};
        else if (b8d2_compressible             ) compressed_data[(16 * 8)-1:0]  = {b8_segments[0], compressed_segments};
        else if (b2d1_compressible             ) compressed_data[(14 * 8)-1:0]  = {b2_segments[0], compressed_segments};
        else if (b4d2_compressible             ) compressed_data[(20 * 8)-1:0]  = {b4_segments[0], compressed_segments};
        else if (b8d4_compressible             ) compressed_data[(24 * 8)-1:0]  = {b8_segments[0], compressed_segments};
        else                                     compressed_data                = cacheline;
    end
endmodule