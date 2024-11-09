module decompressor
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
    input  logic [8 * WORD_WIDTH-1:0]   compressed_cachelines,
    input  logic [7:0]                  compressed_mode,
    input  logic [31:0]                 base_one_hot,
    
    output logic [16 * WORD_WIDTH-1:0]  decompressed_data
);
    logic [8 * WORD_WIDTH-1:0] cacheline_ls_compressed_data;
    logic [3:0]                cacheline_ls_compressed_mode;
    logic [15:0]               cacheline_ls_base_one_hot;
    logic [8 * WORD_WIDTH-1:0] cacheline_ls_decompressed_data;

    logic [8 * WORD_WIDTH-1:0] cacheline_ms_compressed_data;
    logic [3:0]                cacheline_ms_compressed_mode;
    logic [15:0]               cacheline_ms_base_one_hot;
    logic [8 * WORD_WIDTH-1:0] cacheline_ms_decompressed_data;

    little_decompressor little_decompressor_ls (
        .compressed_data                    (cacheline_ls_compressed_data       ),
        .compressed_mode                    (cacheline_ls_compressed_mode       ),
        .base_one_hot                       (cacheline_ls_base_one_hot          ),
        .decompressed_data                  (cacheline_ls_decompressed_data     )
    );

    little_decompressor little_decompressor_ms (
        .compressed_data                    (cacheline_ms_compressed_data       ),
        .compressed_mode                    (cacheline_ms_compressed_mode       ),
        .base_one_hot                       (cacheline_ms_base_one_hot          ),
        .decompressed_data                  (cacheline_ms_decompressed_data     )
    );
    
    assign cacheline_ls_compressed_mode = compressed_mode[3:0]; 
    assign cacheline_ms_compressed_mode = compressed_mode[7:4];

    assign cacheline_ls_base_one_hot = base_one_hot[15:0];
    assign cacheline_ms_base_one_hot = base_one_hot[31:16];

    always_comb
    begin
        case(cacheline_ls_compressed_mode)
            RPV4_CODE:
                begin
                    cacheline_ls_compressed_data = compressed_cachelines[(8*4)-1:0];
                    case(cacheline_ms_compressed_mode)
                        RPV4_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*8)-1:8*4];
                        RPV8_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*12)-1:8*4];
                        B8D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*16)-1:8*4];
                        B4D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*16)-1:8*4];
                        B8D2_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*20)-1:8*4];
                        B2D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*22)-1:8*4];
                        B4D2_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*24)-1:8*4];
                        B8D4_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*28)-1:8*4];
                        NO_COMPR_CODE: cacheline_ms_compressed_data = compressed_cachelines;
                        default: cacheline_ms_compressed_data = compressed_cachelines;
                    endcase
                end
            RPV8_CODE:
                begin
                    cacheline_ls_compressed_data = compressed_cachelines[(8*8)-1:0];
                    case(cacheline_ms_compressed_mode)
                        RPV4_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*12-1:8*8];
                        RPV8_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*16-1:8*8];
                        B8D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*20-1:8*8];
                        B4D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*20-1:8*8];
                        B8D2_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*24-1:8*8];
                        B2D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*26-1:8*8];
                        B4D2_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*28-1:8*8];
                        B8D4_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*32-1:8*8];
                        NO_COMPR_CODE: cacheline_ms_compressed_data = compressed_cachelines;
                        default: cacheline_ms_compressed_data = compressed_cachelines;
                    endcase
                end
            B8D1_CODE:
            begin
                cacheline_ls_compressed_data = compressed_cachelines[12*8-1:0];
                case(cacheline_ms_compressed_mode)
                    RPV4_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*16-1:8*12];
                    RPV8_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*20-1:8*12];
                    B8D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*24-1:8*12];
                    B4D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*24-1:8*12];
                    B8D2_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*28-1:8*12];
                    B2D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*30-1:8*12];
                    B4D2_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*32-1:8*12];
                    NO_COMPR_CODE: cacheline_ms_compressed_data = compressed_cachelines;
                    default: cacheline_ms_compressed_data = compressed_cachelines;
                endcase
            end
            B4D1_CODE:
            begin
                cacheline_ls_compressed_data = compressed_cachelines[12*8-1:0];
                case(cacheline_ms_compressed_mode)
                    RPV4_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*16-1:8*12];
                    RPV8_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*20-1:8*12];
                    B8D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*24-1:8*12];
                    B4D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*24-1:8*12];
                    B8D2_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*28-1:8*12];
                    B2D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*30-1:8*12];
                    B4D2_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*32-1:8*12];
                    NO_COMPR_CODE: cacheline_ms_compressed_data = compressed_cachelines;
                    default: cacheline_ms_compressed_data = compressed_cachelines;
                endcase
            end
            B8D2_CODE:
            begin
                cacheline_ls_compressed_data = compressed_cachelines[16*8-1:0];
                case(cacheline_ms_compressed_mode)
                    RPV4_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*20-1:8*16];
                    RPV8_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*24-1:8*16];
                    B8D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*28-1:8*16];
                    B4D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*28-1:8*16];
                    B8D2_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*32-1:8*16];
                    NO_COMPR_CODE: cacheline_ms_compressed_data = compressed_cachelines;
                    default: cacheline_ms_compressed_data = compressed_cachelines;
                endcase
            end
            B2D1_CODE:
            begin
                cacheline_ls_compressed_data = compressed_cachelines[18*8-1:0];
                case(cacheline_ms_compressed_mode)
                    RPV4_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*22-1:8*18];
                    RPV8_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*26-1:8*18];
                    B8D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*30-1:8*18];
                    B4D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*30-1:8*18];
                    NO_COMPR_CODE: cacheline_ms_compressed_data = compressed_cachelines;
                    default: cacheline_ms_compressed_data = compressed_cachelines;
                endcase
            end
            B4D2_CODE:
            begin
                cacheline_ls_compressed_data = compressed_cachelines[20*8-1:0];
                case(cacheline_ms_compressed_mode)
                    RPV4_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*24-1:8*20];
                    RPV8_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*28-1:8*20];
                    B8D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*32-1:8*20];
                    B4D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*32-1:8*20];
                    NO_COMPR_CODE: cacheline_ms_compressed_data = compressed_cachelines;
                    default: cacheline_ms_compressed_data = compressed_cachelines;
                endcase
            end
            B8D4_CODE:
            begin
                cacheline_ls_compressed_data = compressed_cachelines[24*8-1:0];
                case(cacheline_ms_compressed_mode)
                    RPV4_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*28-1:8*24];
                    RPV8_CODE: cacheline_ms_compressed_data    = compressed_cachelines[8*32-1:8*24];
                    NO_COMPR_CODE: cacheline_ms_compressed_data = compressed_cachelines;
                    default: cacheline_ms_compressed_data = compressed_cachelines;
                endcase
            end
            NO_COMPR_CODE:
            begin
                cacheline_ls_compressed_data = compressed_cachelines;
                    case(cacheline_ms_compressed_mode)
                        RPV4_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*4)-1:0];
                        RPV8_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*8)-1:0];
                        B8D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*12)-1:0];
                        B4D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*12)-1:0];
                        B8D2_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*16)-1:0];
                        B2D1_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*18)-1:0];
                        B4D2_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*20)-1:0];
                        B8D4_CODE: cacheline_ms_compressed_data    = compressed_cachelines[(8*24)-1:0];
                        NO_COMPR_CODE: cacheline_ms_compressed_data = compressed_cachelines;
                        default: cacheline_ms_compressed_data = compressed_cachelines;
                    endcase
            end
            default: cacheline_ls_compressed_data = compressed_cachelines;
        endcase
    end
    
    assign decompressed_data[8 * WORD_WIDTH-1:0]                = cacheline_ls_decompressed_data;
    assign decompressed_data[16 * WORD_WIDTH-1:8 * WORD_WIDTH]  = cacheline_ms_decompressed_data;

endmodule 