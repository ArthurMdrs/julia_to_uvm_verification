module stub (input clk, input rst_n, 
    // Signals from some_vip's interface - begin
        output reg       ready_o,
        input            valid_i,
        input      [7:0] data_i,
        output reg [7:0] data_o,
    // Signals from some_vip's interface - end

    // Signals from another_vip's interface - begin
        output reg       other_ready_o,
        input            other_valid_i,
        input      [7:0] other_address_i,
        output reg [7:0] other_data_o
    // Signals from another_vip's interface - end
    );

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            // Reset logic
        end
        else begin
            // Sequencial logic
        end
    end

    always @(*) begin
        // Combinational logic
    end

endmodule: stub
