module compressor
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
    input  logic [16 * WORD_WIDTH-1:0] cachelines,
    input  logic [ADDR_WIDTH-1:0]      request_address,
    
    output logic [8 * WORD_WIDTH-1:0]  compressed_data,
    output logic [7:0]                 compressed_mode,
    output logic [31:0]                base_one_hot,
    output logic [1:0]                 compressed_valid 
);
    logic [8 * WORD_WIDTH-1:0] cacheline_ls;
    logic [8 * WORD_WIDTH-1:0] cacheline_ls_compressed_data;
    logic [3:0]                cacheline_ls_compressed_mode;
    logic [15:0]               cacheline_ls_base_one_hot;

    logic [8 * WORD_WIDTH-1:0] cacheline_ms;
    logic [8 * WORD_WIDTH-1:0] cacheline_ms_compressed_data;
    logic [3:0]                cacheline_ms_compressed_mode;
    logic [15:0]               cacheline_ms_base_one_hot;

    little_compressor little_compressor_ls (
        .cacheline                          (cacheline_ls                       ),
        .compressed_data                    (cacheline_ls_compressed_data       ),
        .compressed_mode                    (cacheline_ls_compressed_mode       ),
        .base_one_hot                       (cacheline_ls_base_one_hot          )
    );

    little_compressor little_compressor_ms (
        .cacheline                          (cacheline_ms                       ),
        .compressed_data                    (cacheline_ms_compressed_data       ),
        .compressed_mode                    (cacheline_ms_compressed_mode       ),
        .base_one_hot                       (cacheline_ms_base_one_hot          )
    );
    
    assign cacheline_ls = cachelines[8 * WORD_WIDTH-1:0]; 
    assign cacheline_ms = cachelines[16 * WORD_WIDTH-1:8*WORD_WIDTH];

    always_comb
    begin
        compressed_valid = 'b0;
        if((cacheline_ls_compressed_mode == NO_COMPR_CODE) | (cacheline_ms_compressed_mode == NO_COMPR_CODE)) begin
            if(request_address[5]) begin
                compressed_data = cacheline_ms_compressed_data;
                compressed_valid[1] = 1;
            end
            else begin
                compressed_data = cacheline_ls_compressed_data;
                compressed_valid[0] = 1;
            end
        end
        else begin
            case(cacheline_ls_compressed_mode)
                RPV4_CODE:
                    begin
                        compressed_data[(8*4)-1:0] = cacheline_ls_compressed_data;
                        case(cacheline_ms_compressed_mode)
                            RPV4_CODE: compressed_data[(8*8)-1:8*4]     = cacheline_ms_compressed_data;
                            RPV8_CODE: compressed_data[(8*12)-1:8*4]    = cacheline_ms_compressed_data;
                            B8D1_CODE: compressed_data[(8*16)-1:8*4]    = cacheline_ms_compressed_data;
                            B4D1_CODE: compressed_data[(8*16)-1:8*4]    = cacheline_ms_compressed_data;
                            B8D2_CODE: compressed_data[(8*20)-1:8*4]    = cacheline_ms_compressed_data;
                            B2D1_CODE: compressed_data[(8*22)-1:8*4]    = cacheline_ms_compressed_data;
                            B4D2_CODE: compressed_data[(8*24)-1:8*4]    = cacheline_ms_compressed_data;
                            B8D4_CODE: compressed_data[(8*28)-1:8*4]    = cacheline_ms_compressed_data;
                            default: begin
                                if(request_address[5]) begin
                                    compressed_data = cacheline_ms_compressed_data;
                                    compressed_valid[1] = 1;
                                end
                                else begin
                                    compressed_data = cacheline_ls_compressed_data;
                                    compressed_valid[0] = 1;
                                end
                            end
                        endcase
                    end
                RPV8_CODE:
                    begin
                        compressed_data[(8*8)-1:0] = cacheline_ls_compressed_data;
                        case(cacheline_ms_compressed_mode)
                            RPV4_CODE: compressed_data[8*12-1:8*8]    = cacheline_ms_compressed_data;
                            RPV8_CODE: compressed_data[8*16-1:8*8]    = cacheline_ms_compressed_data;
                            B8D1_CODE: compressed_data[8*20-1:8*8]    = cacheline_ms_compressed_data;
                            B4D1_CODE: compressed_data[8*20-1:8*8]    = cacheline_ms_compressed_data;
                            B8D2_CODE: compressed_data[8*24-1:8*8]    = cacheline_ms_compressed_data;
                            B2D1_CODE: compressed_data[8*26-1:8*8]    = cacheline_ms_compressed_data;
                            B4D2_CODE: compressed_data[8*28-1:8*8]    = cacheline_ms_compressed_data;
                            B8D4_CODE: compressed_data[8*32-1:8*8]    = cacheline_ms_compressed_data;
                            default: begin
                                if(request_address[5]) begin
                                    compressed_data = cacheline_ms_compressed_data;
                                    compressed_valid[1] = 1;
                                end
                                else begin
                                    compressed_data = cacheline_ls_compressed_data;
                                    compressed_valid[0] = 1;
                                end
                            end
                        endcase
                    end
                B8D1_CODE:
                    begin
                        compressed_data[12*8-1:0] = cacheline_ls_compressed_data;
                        case(cacheline_ms_compressed_mode)
                            RPV4_CODE: compressed_data[8*16-1:8*12]    = cacheline_ms_compressed_data;
                            RPV8_CODE: compressed_data[8*20-1:8*12]    = cacheline_ms_compressed_data;
                            B8D1_CODE: compressed_data[8*24-1:8*12]    = cacheline_ms_compressed_data;
                            B4D1_CODE: compressed_data[8*24-1:8*12]    = cacheline_ms_compressed_data;
                            B8D2_CODE: compressed_data[8*28-1:8*12]    = cacheline_ms_compressed_data;
                            B2D1_CODE: compressed_data[8*30-1:8*12]    = cacheline_ms_compressed_data;
                            B4D2_CODE: compressed_data[8*32-1:8*12]    = cacheline_ms_compressed_data;
                            default: begin
                                if(request_address[5]) begin
                                    compressed_data = cacheline_ms_compressed_data;
                                    compressed_valid[1] = 1;
                                end
                                else begin
                                    compressed_data = cacheline_ls_compressed_data;
                                    compressed_valid[0] = 1;
                                end
                            end
                        endcase
                    end
                B4D1_CODE:
                    begin
                        compressed_data[12*8-1:0] = cacheline_ls_compressed_data;
                        case(cacheline_ms_compressed_mode)
                            RPV4_CODE: compressed_data[8*16-1:8*12]    = cacheline_ms_compressed_data;
                            RPV8_CODE: compressed_data[8*20-1:8*12]    = cacheline_ms_compressed_data;
                            B8D1_CODE: compressed_data[8*24-1:8*12]    = cacheline_ms_compressed_data;
                            B4D1_CODE: compressed_data[8*24-1:8*12]    = cacheline_ms_compressed_data;
                            B8D2_CODE: compressed_data[8*28-1:8*12]    = cacheline_ms_compressed_data;
                            B2D1_CODE: compressed_data[8*30-1:8*12]    = cacheline_ms_compressed_data;
                            B4D2_CODE: compressed_data[8*32-1:8*12]    = cacheline_ms_compressed_data;
                            default: begin
                                if(request_address[5]) begin
                                    compressed_data = cacheline_ms_compressed_data;
                                    compressed_valid[1] = 1;
                                end
                                else begin
                                    compressed_data = cacheline_ls_compressed_data;
                                    compressed_valid[0] = 1;
                                end
                            end
                        endcase
                    end
                B8D2_CODE:
                    begin
                        compressed_data[16*8-1:0] = cacheline_ls_compressed_data;
                        case(cacheline_ms_compressed_mode)
                            RPV4_CODE: compressed_data[8*20-1:8*16]    = cacheline_ms_compressed_data;
                            RPV8_CODE: compressed_data[8*24-1:8*16]    = cacheline_ms_compressed_data;
                            B8D1_CODE: compressed_data[8*28-1:8*16]    = cacheline_ms_compressed_data;
                            B4D1_CODE: compressed_data[8*28-1:8*16]    = cacheline_ms_compressed_data;
                            B8D2_CODE: compressed_data[8*32-1:8*16]    = cacheline_ms_compressed_data;
                            default: begin
                                if(request_address[5]) begin
                                    compressed_data = cacheline_ms_compressed_data;
                                    compressed_valid[1] = 1;
                                end
                                else begin
                                    compressed_data = cacheline_ls_compressed_data;
                                    compressed_valid[0] = 1;
                                end
                            end
                        endcase
                    end
                B2D1_CODE:
                    begin
                        compressed_data[18*8-1:0] = cacheline_ls_compressed_data;
                        case(cacheline_ms_compressed_mode)
                            RPV4_CODE: compressed_data[8*22-1:8*18]    = cacheline_ms_compressed_data;
                            RPV8_CODE: compressed_data[8*26-1:8*18]    = cacheline_ms_compressed_data;
                            B8D1_CODE: compressed_data[8*30-1:8*18]    = cacheline_ms_compressed_data;
                            B4D1_CODE: compressed_data[8*30-1:8*18]    = cacheline_ms_compressed_data;
                            default: begin
                                if(request_address[5]) begin
                                    compressed_data = cacheline_ms_compressed_data;
                                    compressed_valid[1] = 1;
                                end
                                else begin
                                    compressed_data = cacheline_ls_compressed_data;
                                    compressed_valid[0] = 1;
                                end
                            end
                        endcase
                    end
                B4D2_CODE:
                    begin
                        compressed_data[20*8-1:0] = cacheline_ls_compressed_data;
                        case(cacheline_ms_compressed_mode)
                            RPV4_CODE: compressed_data[8*24-1:8*20]    = cacheline_ms_compressed_data;
                            RPV8_CODE: compressed_data[8*28-1:8*20]    = cacheline_ms_compressed_data;
                            B8D1_CODE: compressed_data[8*32-1:8*20]    = cacheline_ms_compressed_data;
                            B4D1_CODE: compressed_data[8*32-1:8*20]    = cacheline_ms_compressed_data;
                            default: begin
                                if(request_address[5]) begin
                                    compressed_data = cacheline_ms_compressed_data;
                                    compressed_valid[1] = 1;
                                end
                                else begin
                                    compressed_data = cacheline_ls_compressed_data;
                                    compressed_valid[0] = 1;
                                end
                            end
                        endcase
                    end
                B8D4_CODE:
                    begin
                        compressed_data[24*8-1:0] = cacheline_ls_compressed_data;
                        case(cacheline_ms_compressed_mode)
                            RPV4_CODE: compressed_data[8*28-1:8*24]    = cacheline_ms_compressed_data;
                            RPV8_CODE: compressed_data[8*32-1:8*24]    = cacheline_ms_compressed_data;
                            default: begin
                                if(request_address[5]) begin
                                    compressed_data = cacheline_ms_compressed_data;
                                    compressed_valid[1] = 1;
                                end
                                else begin
                                    compressed_data = cacheline_ls_compressed_data;
                                    compressed_valid[0] = 1;
                                end
                            end
                        endcase
                    end
                default: 
                    begin
                        if(request_address[5])  compressed_data = cacheline_ms_compressed_data;
                        else                    compressed_data = cacheline_ls_compressed_data;
                    end
            endcase
        end
    end

    assign compressed_mode = {cacheline_ms_compressed_mode, cacheline_ls_compressed_mode};
    assign base_one_hot[15:0] = cacheline_ls_base_one_hot;
    assign base_one_hot[31:16] = cacheline_ms_base_one_hot;
endmodule 