module cache 
#(
    parameter TAG_FIELD         = 19,
    parameter DATA_FIELD        = 32 * 8,
    parameter ADDR_WIDTH        = 32,
    parameter WORD_WIDTH        = 32,
    parameter CACHELINE_COUNT   = 1024
)
(
    input  logic                                    clk,                    // clock
    input  logic                                    rst,                    // reset

    input  logic                                    cache_op_read,
    
    // write chan
    input  logic [2 + TAG_FIELD + DATA_FIELD-1:0]   cache_write_data,       // request write cacheline                            
    input  logic [$clog2(CACHELINE_COUNT)-1:0]      cache_write_index,      // request index of cacheline
    input  logic                                    cache_write_on_demand,
    input  logic                                    cache_write_word_valid,

    // read chan
    input  logic [6:0]                              cache_read_index,       // request index of cacheline inside one way 
    input  logic [TAG_FIELD-1:0]                    cache_read_tag,         // request tag
    input  logic [3:0]                              cache_read_word_addr,   // request addr of word inside cacheline 
    output logic                                    cache_read_hit,
    output logic [WORD_WIDTH-1:0]                   cache_read_word_data,
    output logic [9:0]                              cache_read_cacheline_index10,
    input  logic [7:0]                              cache_read_compressed_mode,
    input  logic [31:0]                             cache_read_base_one_hot
);
    logic [2 + TAG_FIELD + DATA_FIELD-1:0] cache [CACHELINE_COUNT-1:0];
    logic [2 + TAG_FIELD + DATA_FIELD-1:0] cache_read_cacheline;
    logic [2 + TAG_FIELD + DATA_FIELD-1:0] cache_write_cacheline;

    logic [DATA_FIELD-1:0] decompressed_data;

    always_comb
    begin
        cache_write_cacheline = cache[cache_write_index];
        for(int i = 0; i < (2 + TAG_FIELD + DATA_FIELD); i++) begin
            if(cache_write_data[i] | !cache_write_data[i])                  cache_write_cacheline[i] = cache_write_data[i];
            else if(cache_write_cacheline[i] | !cache_write_cacheline[i])   cache_write_cacheline[i] = cache_write_cacheline[i];  
            else                                                            cache_write_cacheline[i] = 0;
        end
    end

    always_comb
    begin
        cache_read_cacheline_index10 = 'b0;
        cache_read_cacheline         = 'b0;
        if      (cache_read_tag == cache[cache_read_index           ][TAG_FIELD + DATA_FIELD-1:DATA_FIELD] & 
                (cache[cache_read_index][1 + TAG_FIELD + DATA_FIELD-1] == 1 & !cache_read_word_addr[3] | 
                (cache[cache_read_index][2 + TAG_FIELD + DATA_FIELD-1] == 1 & cache_read_word_addr[3])))  
        begin 
            cache_read_cacheline_index10 = cache_read_index;
            cache_read_cacheline = cache[cache_read_cacheline_index10];
        end
        else if (cache_read_tag == cache[cache_read_index + 10'h0_80][TAG_FIELD + DATA_FIELD-1:DATA_FIELD] &
                (cache[cache_read_index + 10'h0_80][1 + TAG_FIELD + DATA_FIELD-1] == 1 & !cache_read_word_addr[3] | 
                (cache[cache_read_index + 10'h0_80][2 + TAG_FIELD + DATA_FIELD-1] == 1 & cache_read_word_addr[3])))  
        begin  
            cache_read_cacheline_index10 = cache_read_index + 10'h0_80;
            cache_read_cacheline = cache[cache_read_cacheline_index10]; 
        end
        else if (cache_read_tag == cache[cache_read_index + 10'h1_00][TAG_FIELD + DATA_FIELD-1:DATA_FIELD] &
                (cache[cache_read_index + 10'h1_00][1 + TAG_FIELD + DATA_FIELD-1] == 1 & !cache_read_word_addr[3] | 
                (cache[cache_read_index + 10'h1_00][2 + TAG_FIELD + DATA_FIELD-1] == 1 & cache_read_word_addr[3])))  
        begin
            cache_read_cacheline_index10 = cache_read_index + 10'h1_00;
            cache_read_cacheline = cache[cache_read_cacheline_index10];
        end
        else if (cache_read_tag == cache[cache_read_index + 10'h1_80][TAG_FIELD + DATA_FIELD-1:DATA_FIELD] &
                (cache[cache_read_index + 10'h1_80][1 + TAG_FIELD + DATA_FIELD-1] == 1 & !cache_read_word_addr[3] | 
                (cache[cache_read_index + 10'h1_80][2 + TAG_FIELD + DATA_FIELD-1] == 1 & cache_read_word_addr[3])))   
        begin
            cache_read_cacheline_index10 = cache_read_index + 10'h1_80;
            cache_read_cacheline = cache[cache_read_cacheline_index10];
        end
        else if (cache_read_tag == cache[cache_read_index + 10'h2_00][TAG_FIELD + DATA_FIELD-1:DATA_FIELD] &
                (cache[cache_read_index + 10'h2_00][1 + TAG_FIELD + DATA_FIELD-1] == 1 & !cache_read_word_addr[3] | 
                (cache[cache_read_index + 10'h2_00][2 + TAG_FIELD + DATA_FIELD-1] == 1 & cache_read_word_addr[3])))    
        begin
            cache_read_cacheline_index10 = cache_read_index + 10'h2_00;
            cache_read_cacheline = cache[cache_read_cacheline_index10];
        end
        else if (cache_read_tag == cache[cache_read_index + 10'h2_80][TAG_FIELD + DATA_FIELD-1:DATA_FIELD] &
                (cache[cache_read_index + 10'h2_80][1 + TAG_FIELD + DATA_FIELD-1] == 1 & !cache_read_word_addr[3] | 
                (cache[cache_read_index + 10'h2_80][2 + TAG_FIELD + DATA_FIELD-1] == 1 & cache_read_word_addr[3])))    
        begin
            cache_read_cacheline_index10 = cache_read_index + 10'h2_80;
            cache_read_cacheline = cache[cache_read_cacheline_index10];
        end
        else if (cache_read_tag == cache[cache_read_index + 10'h3_00][TAG_FIELD + DATA_FIELD-1:DATA_FIELD] &
                (cache[cache_read_index + 10'h3_00][1 + TAG_FIELD + DATA_FIELD-1] == 1 & !cache_read_word_addr[3] | 
                (cache[cache_read_index + 10'h3_00][2 + TAG_FIELD + DATA_FIELD-1] == 1 & cache_read_word_addr[3])))    
        begin
            cache_read_cacheline_index10 = cache_read_index + 10'h3_00;
            cache_read_cacheline = cache[cache_read_cacheline_index10];
        end
        else if (cache_read_tag == cache[cache_read_index + 10'h3_80][TAG_FIELD + DATA_FIELD-1:DATA_FIELD] &
                (cache[cache_read_index + 10'h3_80][1 + TAG_FIELD + DATA_FIELD-1] == 1 & !cache_read_word_addr[3] | 
                (cache[cache_read_index + 10'h3_80][2 + TAG_FIELD + DATA_FIELD-1] == 1 & cache_read_word_addr[3])))    
        begin
            cache_read_cacheline_index10 = cache_read_index + 10'h3_80;
            cache_read_cacheline = cache[cache_read_cacheline_index10];
        end
    end

    always_ff @(posedge clk)
    begin
        if(cache_write_word_valid | cache_write_on_demand) begin
            cache[cache_write_index]   <= cache_write_cacheline;
        end
    end

    decompressor decompressor(
        .compressed_cachelines      (cache_read_cacheline[DATA_FIELD-1:0]),
        .compressed_mode            (cache_read_compressed_mode),
        .base_one_hot               (cache_read_base_one_hot),
        .cacheline_select_signal    (cache_read_word_addr[3]),
        .decompressed_data          (decompressed_data)
    );

    always_comb 
    begin
        cache_read_word_data = 'b0;
        case(cache_read_word_addr[2:0]) 
            3'b000: cache_read_word_data     = decompressed_data[31:0];
            3'b001: cache_read_word_data     = decompressed_data[63:32];
            3'b010: cache_read_word_data     = decompressed_data[95:64];
            3'b011: cache_read_word_data     = decompressed_data[127:96];
            3'b100: cache_read_word_data     = decompressed_data[159:128];
            3'b101: cache_read_word_data     = decompressed_data[191:160];
            3'b110: cache_read_word_data     = decompressed_data[223:192];
            3'b111: cache_read_word_data     = decompressed_data[255:224];
            default: cache_read_word_data    = 'b0;
        endcase
    end
    
    assign cache_read_hit = ( (cache_read_tag == cache_read_cacheline[TAG_FIELD + DATA_FIELD-1:DATA_FIELD]) & 
                                    (cache_read_cacheline[1 + TAG_FIELD + DATA_FIELD-1] == 1 & !cache_read_word_addr[3]) |
                                    (cache_read_cacheline[2 + TAG_FIELD + DATA_FIELD-1] == 1 & cache_read_word_addr[3]) );
    
endmodule