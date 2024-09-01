module system_with_compression
(
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] address,
    input  logic        op_rd,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    output logic        cache_hit
);
    logic read_hit;
    logic cache_hit_stall;
    logic [31:0] read_word;
    logic [18:0] read_tag;
    logic [6:0] read_index;
    logic [9:0] write_index;
    logic [3:0] read_word_addr;
    logic [2 + 19 + 256-1:0] write_cacheline;
    logic [31:0] memory_addr;
    logic memory_write_en;
    logic [31:0] memory_write_data;
    logic [31:0] memory_read_data;
    logic memory_read_ready;
    logic memory_read_valid;
    logic memory_read_addr_valid;
    logic write_on_demand;
    logic write_word_valid;
    logic [9:0] cache_read_cacheline_index10;
    logic [31:0] read_base_one_hot;
    logic [7:0] read_compressed_mode;

    cache cache (
        .clk                        (clk                    ),
        .rst                        (rst                    ),
        .cache_op_read              (op_rd                  ),
        .cache_write_data           (write_cacheline        ),
        .cache_write_index          (write_index            ),
        .cache_write_on_demand      (write_on_demand        ),
        .cache_write_word_valid     (write_word_valid       ),
        .cache_read_index           (read_index             ),
        .cache_read_tag             (read_tag               ),
        .cache_read_word_addr       (read_word_addr         ),   
        .cache_read_hit             (read_hit               ),
        .cache_read_word_data       (read_word              ),
        .cache_read_cacheline_index10(cache_read_cacheline_index10),
        .cache_read_base_one_hot    (read_base_one_hot      ),
        .cache_read_compressed_mode (read_compressed_mode   )        
    );

    cache_controller cache_controller (
        .clk                        (clk                ),
        .rst                        (rst                ),
        .request_address            (address            ),
        .request_op_read            (op_rd              ),
        .request_read_word          (rdata              ),
        .request_write_word         (wdata              ),
        .cache_hit_stall            (cache_hit_stall    ),
        .read_hit                   (read_hit           ),
        .read_word                  (read_word          ),
        .read_tag                   (read_tag           ),
        .read_index                 (read_index         ),    
        .read_word_addr             (read_word_addr     ),
        .read_cacheline_index10     (cache_read_cacheline_index10),
        .read_compressed_mode       (read_compressed_mode),
        .read_base_one_hot          (read_base_one_hot  ),
        .write_index                (write_index        ),
        .write_cacheline            (write_cacheline    ),
        .write_on_demand            (write_on_demand    ),
        .write_word_valid           (write_word_valid   ),
        .memory_addr                (memory_addr        ),
        .memory_write_en            (memory_write_en    ),
        .memory_write_data          (memory_write_data  ),
        .memory_read_data           (memory_read_data   ),
        .memory_read_ready          (memory_read_ready  ),
        .memory_read_valid          (memory_read_valid  ),
        .memory_read_addr_valid     (memory_read_addr_valid)
    );

    main_memory main_memory (
        .clk                        (clk                ),
        .rst                        (rst                ),
        .write_data                 (memory_write_data  ),
        .write_addr                 (memory_addr        ),
        .write_en                   (memory_write_en    ),
        .read_addr                  (memory_addr        ),
        .read_data                  (memory_read_data   ),
        .read_ready                 (memory_read_ready  ),
        .read_valid                 (memory_read_valid  ),
        .read_addr_valid            (memory_read_addr_valid)
    );

    always_ff @(posedge clk, negedge rst)
    begin
        if(!rst)                cache_hit <= 0;
        else if  (cache_hit)    cache_hit <= 0;
        else                    cache_hit <= (op_rd & !cache_hit_stall) ? read_hit : 0;
    end
endmodule