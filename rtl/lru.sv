module lru (
    input  logic [3:0]      cache_counter0,
    input  logic [3:0]      cache_counter1,
    input  logic [3:0]      cache_counter2,
    input  logic [3:0]      cache_counter3,
    input  logic [3:0]      cache_counter4,
    input  logic [3:0]      cache_counter5,
    input  logic [3:0]      cache_counter6,
    input  logic [3:0]      cache_counter7,
    input  logic [6:0]      index7,
    output logic [9:0]      index10
);
    logic [4:0]                 min_cacheline_counter [6:0];
    
    assign min_cacheline_counter[0] = cache_counter0 < cache_counter1 ? cache_counter0 : cache_counter1; 
    assign min_cacheline_counter[1] = cache_counter2 < cache_counter3 ? cache_counter2 : cache_counter3; 
    assign min_cacheline_counter[2] = cache_counter4 < cache_counter5 ? cache_counter4 : cache_counter5;
    assign min_cacheline_counter[3] = cache_counter6 < cache_counter7 ? cache_counter6 : cache_counter7;

    assign min_cacheline_counter[4] = min_cacheline_counter[0] < min_cacheline_counter[1] ? min_cacheline_counter[0] : min_cacheline_counter[1];
    assign min_cacheline_counter[5] = min_cacheline_counter[2] < min_cacheline_counter[3] ? min_cacheline_counter[2] : min_cacheline_counter[3];
            
    assign min_cacheline_counter[6] = min_cacheline_counter[4] < min_cacheline_counter[5] ? min_cacheline_counter[4] : min_cacheline_counter[5];  

    always_comb
    begin
        index10 = 'b0;
        case(min_cacheline_counter[6])
            cache_counter0:   index10 = index7;
            cache_counter1:   index10 = index7 + 10'h0_80;
            cache_counter2:   index10 = index7 + 10'h1_00;
            cache_counter3:   index10 = index7 + 10'h1_80;
            cache_counter4:   index10 = index7 + 10'h2_00;
            cache_counter5:   index10 = index7 + 10'h2_80;
            cache_counter6:   index10 = index7 + 10'h3_00;
            cache_counter7:   index10 = index7 + 10'h3_80;
            default: index10 = 'b0;
        endcase
    end

endmodule