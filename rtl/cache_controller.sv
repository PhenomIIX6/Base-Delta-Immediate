module cache_controller
#(
    parameter TAG_FIELD         = 20,
    parameter DATA_FIELD        = 32 * 8,
    parameter ADDR_WIDTH        = 32,
    parameter WORD_WIDTH        = 32,
    parameter CACHELINE_COUNT   = 1024
)
(
    input  logic                                    clk,
    input  logic                                    rst,
    
    // CPU <-> Cache_controller intf
    input  logic [ADDR_WIDTH-1:0]                   request_address,        // Request address
    input  logic                                    request_op_read,        // Request operation type: read or write?
    output logic [WORD_WIDTH-1:0]                   request_read_word,      // Word from cache
    input  logic [WORD_WIDTH-1:0]                   request_write_word,     // Word to write in cache
    output logic                                    request_cache_hit,      // Cache hit
    
    // Cache_controller <-> Cache intf
    input  logic                                    read_hit,
    input  logic [WORD_WIDTH-1:0]                   read_word,
    output logic [TAG_FIELD-1:0]                    read_tag,
    output logic [6:0]                              read_index,
    output logic [2:0]                              read_word_addr, 
    input  logic [9:0]                              read_cacheline_index10,

    output logic [9:0]                              write_index,
    output logic [1 + TAG_FIELD + DATA_FIELD-1:0]   write_cacheline,
    output logic                                    write_on_demand,
    output logic                                    write_word_valid,

    // Cache_controller <-> Main_memory intf
    output logic [ADDR_WIDTH-1:0]                   memory_addr,
    output logic                                    memory_write_en,
    output logic [WORD_WIDTH-1:0]                   memory_write_data,
    input  logic [WORD_WIDTH-1:0]                   memory_read_data,
    input  logic                                    memory_read_ready,
    input  logic                                    memory_read_valid,
    output logic                                    memory_read_addr_valid
);
    logic [4-1:0] cache_dir_state [CACHELINE_COUNT-1:0]; // 4 bit counter for LRU
   
    logic [2:0] cache_on_demand_read_counter;
    logic [2:0] cache_on_demand_fill_counter;

    logic [9:0] write_index_lru;
    logic       cache_hit_stall;

    always_ff @(posedge clk, negedge rst) // LRU counter increment
    begin
        if(!rst) begin
            for(int i = 0; i < CACHELINE_COUNT; i++) cache_dir_state[i] <= 'b0;
        end
        else if(request_op_read & read_hit) begin
            cache_dir_state[read_cacheline_index10][3:0]  <= cache_dir_state[read_cacheline_index10][3:0] + 1;
        end
    end

    // LRU cacheline replace
    lru LRU(
        .cache_counter0   (cache_dir_state[read_index           ][3:0]    ),
        .cache_counter1   (cache_dir_state[read_index + 10'h0_80][3:0]    ),
        .cache_counter2   (cache_dir_state[read_index + 10'h1_00][3:0]    ),
        .cache_counter3   (cache_dir_state[read_index + 10'h1_80][3:0]    ),
        .cache_counter4   (cache_dir_state[read_index + 10'h2_00][3:0]    ),
        .cache_counter5   (cache_dir_state[read_index + 10'h2_80][3:0]    ),
        .cache_counter6   (cache_dir_state[read_index + 10'h3_00][3:0]    ),
        .cache_counter7   (cache_dir_state[read_index + 10'h3_80][3:0]    ),
        .index7           (read_index                                     ),
        .index10          (write_index_lru                                )
    );

    always_ff @(posedge clk or negedge rst)  
    begin
        if(!rst) begin
            cache_on_demand_read_counter <= 'b0;
            cache_on_demand_fill_counter <= 'b0;
            write_on_demand              <= 'b0;
            memory_write_en              <= 'b0;
            memory_read_addr_valid       <= 'b0;
            write_word_valid             <= 'b0;
            cache_hit_stall              <= 'b0;
        end
        else if(request_op_read & read_hit ) begin
            request_read_word               <= read_word;
            write_on_demand                 <= 0;
            cache_on_demand_read_counter    <= 0;
            cache_on_demand_fill_counter    <= 0;
            memory_read_addr_valid          <= 0;
            memory_write_en                 <= 0;
            write_word_valid                <= 0;
            cache_hit_stall                 <= 0;
        end
        else if(request_op_read & !read_hit ) begin
            cache_hit_stall                 <= 0;
            memory_write_en                 <= 0;
            write_word_valid                <= 0;
            if(memory_read_ready) begin
                memory_addr                     <= ((request_address >> 5) << 3) + cache_on_demand_read_counter;
                memory_read_addr_valid          <= 1;
                cache_on_demand_read_counter    <= cache_on_demand_read_counter + 1; 
            end
            if(memory_read_valid) begin
                write_on_demand <= 1;
                write_index     <= write_index_lru;
                write_cacheline <= 'h?;
                case(cache_on_demand_fill_counter)
                    3'b000: write_cacheline[31:0]       <= memory_read_data;
                    3'b001: write_cacheline[63:32]      <= memory_read_data;
                    3'b010: write_cacheline[95:64]      <= memory_read_data;
                    3'b011: write_cacheline[127:96]     <= memory_read_data;
                    3'b100: write_cacheline[159:128]    <= memory_read_data;
                    3'b101: write_cacheline[191:160]    <= memory_read_data;
                    3'b110: write_cacheline[223:192]    <= memory_read_data;
                    3'b111: begin
                                write_cacheline[TAG_FIELD + DATA_FIELD-1:DATA_FIELD] <= read_tag;
                                write_cacheline[255:224] <= memory_read_data;
                                write_cacheline[1 + TAG_FIELD + DATA_FIELD-1] <= 1;
                            end
                    default: write_cacheline <= 'b0;
                endcase
                cache_on_demand_fill_counter <= cache_on_demand_fill_counter + 1;
            end
        end
        else if(!request_op_read) begin
            cache_hit_stall     <= read_hit;
            write_on_demand     <= 0;
            memory_addr         <= request_address >> 2; 
            memory_write_data   <= request_write_word;
            memory_write_en     <= 1;
            if(read_hit) begin
                write_cacheline     <= 'h?;
                write_word_valid    <= 1;
                write_index         <= read_cacheline_index10;
                case(read_word_addr)
                    3'b000: write_cacheline[31:0]       <= request_write_word;
                    3'b001: write_cacheline[63:32]      <= request_write_word;
                    3'b010: write_cacheline[95:64]      <= request_write_word;
                    3'b011: write_cacheline[127:96]     <= request_write_word;
                    3'b100: write_cacheline[159:128]    <= request_write_word;
                    3'b101: write_cacheline[191:160]    <= request_write_word;
                    3'b110: write_cacheline[223:192]    <= request_write_word;
                    3'b111: write_cacheline[255:224]    <= request_write_word;
                    default: write_cacheline            <= 'b0;
                endcase
            end
        end
    end

    assign read_word_addr    = request_address[4:2];
    assign read_tag          = request_address[31:12];
    assign read_index        = request_address[11:5];

    always_ff @(posedge clk, negedge rst)
    begin
        if(!rst)                        request_cache_hit <= 0;
        else if  (request_cache_hit)    request_cache_hit <= 0;
        else                            request_cache_hit <= (request_op_read & !cache_hit_stall) ? read_hit : 0;
    end

endmodule