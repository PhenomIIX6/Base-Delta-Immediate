module cache_controller
#(
    parameter TAG_FIELD         = 19,
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
    output logic                                    cache_hit_stall,
    
    // Cache_controller <-> Cache intf
    input  logic                                    read_hit,
    input  logic [WORD_WIDTH-1:0]                   read_word,
    output logic [TAG_FIELD-1:0]                    read_tag,
    output logic [6:0]                              read_index,
    output logic [3:0]                              read_word_addr, 
    input  logic [9:0]                              read_cacheline_index10,
    output logic [31:0]                             read_base_one_hot,
    output logic [7:0]                              read_compressed_mode,

    output logic [9:0]                              write_index,
    output logic [2 + TAG_FIELD + DATA_FIELD-1:0]   write_cacheline,
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
    logic [8+32+4-1:0] cache_dir_state [CACHELINE_COUNT-1:0]; // 8 bit for compressor mode, 32 bit for compressor segments, 4 bit counter for LRU

    logic [16 * WORD_WIDTH-1:0] two_cacheline;
    logic two_cacheline_data_valid;
    logic [8 * WORD_WIDTH-1:0] compressed_data;
    logic [7:0]                compressed_mode;
    logic [31:0]               base_one_hot;
    logic [1:0]                compressed_valid;

    logic [3:0] cache_on_demand_read_counter;
    logic [3:0] cache_on_demand_fill_counter;

    logic [9:0] write_index_lru;

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

    compressor compressor(
        .cachelines         (two_cacheline      ),
        .request_address    (request_address    ),
        .compressed_data    (compressed_data    ),
        .compressed_mode    (compressed_mode    ),
        .base_one_hot       (base_one_hot       ),
        .compressed_valid   (compressed_valid   )
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
            two_cacheline_data_valid     <= 0;
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
            two_cacheline_data_valid        <= 0;
        end
        else if(request_op_read & !read_hit ) begin
            cache_hit_stall                 <= 0;
            memory_write_en                 <= 0;
            write_word_valid                <= 0;
            two_cacheline_data_valid        <= 0;
            if(memory_read_ready) begin
                memory_addr                     <= ((request_address >> 6) << 4) + cache_on_demand_read_counter;
                memory_read_addr_valid          <= 1;
                cache_on_demand_read_counter    <= cache_on_demand_read_counter + 1; 
            end
            if(memory_read_valid) begin
                case(cache_on_demand_fill_counter)
                    4'b0000: two_cacheline[31:0]       <= memory_read_data;
                    4'b0001: two_cacheline[63:32]      <= memory_read_data;
                    4'b0010: two_cacheline[95:64]      <= memory_read_data;
                    4'b0011: two_cacheline[127:96]     <= memory_read_data;
                    4'b0100: two_cacheline[159:128]    <= memory_read_data;
                    4'b0101: two_cacheline[191:160]    <= memory_read_data;
                    4'b0110: two_cacheline[223:192]    <= memory_read_data;
                    4'b0111: two_cacheline[255:224]    <= memory_read_data;
                    4'b1000: two_cacheline[287:256]    <= memory_read_data;
                    4'b1001: two_cacheline[319:288]    <= memory_read_data;
                    4'b1010: two_cacheline[351:320]    <= memory_read_data;
                    4'b1011: two_cacheline[383:352]    <= memory_read_data;
                    4'b1100: two_cacheline[415:384]    <= memory_read_data;
                    4'b1101: two_cacheline[447:416]    <= memory_read_data;
                    4'b1110: two_cacheline[479:448]    <= memory_read_data;
                    4'b1111: begin 
                        two_cacheline[511:480]    <= memory_read_data;
                        two_cacheline_data_valid  <= 1;
                    end
                endcase
                cache_on_demand_fill_counter <= cache_on_demand_fill_counter + 1;
            end
            if(two_cacheline_data_valid) begin
                write_on_demand             <= 1;
                write_index                 <= write_index_lru;
                two_cacheline_data_valid    <= 0;
                write_cacheline[2 + TAG_FIELD + DATA_FIELD-1:TAG_FIELD + DATA_FIELD]    <= compressed_valid;
                write_cacheline[8 * WORD_WIDTH-1:0]                                     <= compressed_data;
                write_cacheline[TAG_FIELD + DATA_FIELD-1:DATA_FIELD]                    <= request_address[31:13];
                cache_dir_state[write_index_lru][8+32+4-1:32+4]                         <= compressed_mode;
                cache_dir_state[write_index_lru][32+4-1:4]                              <= base_one_hot; 
            end
        end
        else if(!request_op_read) begin
            cache_hit_stall     <= 1;
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

    assign read_word_addr       = request_address[5:2];
    assign read_tag             = request_address[31:13];
    assign read_index           = request_address[12:6];

    assign read_base_one_hot = cache_dir_state[read_cacheline_index10][32+4-1:4];
    assign read_compressed_mode = cache_dir_state[read_cacheline_index10][8+32+4-1:32+4];
endmodule