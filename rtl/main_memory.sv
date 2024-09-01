module main_memory
#(
    parameter WORD_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)
(
    input  logic                     clk,
    input  logic                     rst,

    input  logic [WORD_WIDTH-1:0]    write_data,
    input  logic [ADDR_WIDTH-2-1:0]  write_addr,
    input  logic                     write_en,

    input  logic [ADDR_WIDTH-2-1:0]  read_addr,
    input  logic                     read_addr_valid,
    output logic [WORD_WIDTH-1:0]    read_data,
    output logic                     read_ready,
    output logic                     read_valid
);
    logic [WORD_WIDTH-1:0] mem [2 ** 20:0];
    logic [WORD_WIDTH-1:0] write_line;

    always_comb
    begin
        for(int i = 0; i < WORD_WIDTH; i++) begin
             if(write_data[i] | !write_data[i]) write_line[i] = write_data[i];
             else                               write_line[i] = 0;
        end
    end

    always_ff @(posedge clk, negedge rst)
    begin
        if(!rst) begin
            read_ready <= 0;
            read_valid <= 0;
        end
        else if(write_en) begin
            mem[write_addr] <= write_line;
            read_ready <= 0;
            read_valid <= 0;
        end
        else begin
            read_ready <= 1;
            if(read_ready & read_addr_valid) begin
                read_data  <= mem[read_addr];
                read_valid <= read_addr_valid;
            end 
            else read_valid <= 0;
        end
    end

endmodule