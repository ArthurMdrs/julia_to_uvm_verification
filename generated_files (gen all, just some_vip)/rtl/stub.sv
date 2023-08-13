module stub (input clk, input rst_n, 
    // Signals from some_vip's interface - begin
        output reg       ready_o,
        input            valid_i,
        input      [7:0] data_i,
        output reg [7:0] data_o
    // Signals from some_vip's interface - end
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
