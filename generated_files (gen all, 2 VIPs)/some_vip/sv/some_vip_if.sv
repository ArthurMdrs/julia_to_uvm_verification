interface some_vip_if (input clk, input rst_n );

    import uvm_pkg::*;    
    `include "uvm_macros.svh"
    import some_vip_pkg::*;

    // Interface Signals - Begin
    logic       ready_o;
    logic       valid_i;
    logic [7:0] data_i;
    logic [7:0] data_o;
    // Interface Signals - End

    // signal for transaction recording
    bit monstart, drvstart;

    task some_vip_reset();
        @(negedge rst_n);
        monstart = 0;
        drvstart = 0;
        disable send_to_dut;
    endtask

    // Gets a packet and drive it into the DUT
    task send_to_dut(some_vip_packet req);
        // Logic to start recording transaction

        // trigger for transaction recording
        #1;
        drvstart = 1'b1;

        // Driver logic 
        `uvm_info("SOME_VIP INTERFACE", req.convert2string(), UVM_HIGH)

        // Reset trigger
        drvstart = 1'b0;
    endtask : send_to_dut

    // Collect Packets
    task collect_packet(some_vip_packet req);
        // Logic to start recording transaction

        // trigger for transaction recording
        monstart = 1'b1;

        // Driver logic 

        // Reset trigger
        monstart = 1'b0;
    endtask : collect_packet

endinterface : some_vip_if
