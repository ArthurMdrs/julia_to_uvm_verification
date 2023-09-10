module top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // VIP imports - begin
        import some_vip_pkg::*;
        import another_vip_pkg::*;
    // VIP imports - end

    `include "tests.sv"

    bit clk, rst_n;
    bit run_clock;

    // Virtual interfaces instances - begin
        some_vip_if vif_some_vip(.clk(clk), .rst_n(rst_n));
        another_vip_if vif_another_vip(.clk(clk), .rst_n(rst_n));
    // Virtual interfaces instances - end


    stub dut(
        .clk(clk),
        .rst_n(rst_n),
        // Signals from some_vip's interface - begin
            .ready_o(vif_some_vip.ready_o),
            .valid_i(vif_some_vip.valid_i),
            .data_i(vif_some_vip.data_i),
            .data_o(vif_some_vip.data_o),
        // Signals from some_vip's interface - end

        // Signals from another_vip's interface - begin
            .another_ready_o(vif_another_vip.another_ready_o),
            .another_valid_i(vif_another_vip.another_valid_i),
            .another_data_i(vif_another_vip.another_data_i),
            .another_data_o(vif_another_vip.another_data_o)
        // Signals from another_vip's interface - end
        );

    initial begin
        clk = 0;
        rst_n = 1;
        #3 rst_n = 0;
        #3 rst_n = 1;
    end
    always #2 clk=~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;

        // Virtual interfaces send to VIPs - begin
            some_vip_vif_config::set(null,"uvm_test_top.agent_some_vip.*","vif",vif_some_vip);
            another_vip_vif_config::set(null,"uvm_test_top.agent_another_vip.*","vif",vif_another_vip);
        // Virtual interfaces send to VIPs - end

        run_test("random_test");
    end

endmodule: top
