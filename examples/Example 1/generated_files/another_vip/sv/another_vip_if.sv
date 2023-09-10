    interface another_vip_if (input clk, input rst_n );

        import uvm_pkg::*;    
        `include "uvm_macros.svh"
        import another_vip_pkg::*;

        // Interface Signals - Begin
        logic       another_ready_o;
        logic       another_valid_i;
        logic [7:0] another_data_i;
        logic [7:0] another_data_o;
        // Interface Signals - End

        // Signals for transaction recording
        bit monstart, drvstart;
        
        // Signal to control monitor activity
        bit valid_data;
        // Test packet
        another_vip_packet pkt = new("PKT");

        task another_vip_reset();
            @(negedge rst_n);
            monstart = 0;
            drvstart = 0;
            disable send_to_dut;
        endtask

        // Gets a packet and drive it into the DUT
        task send_to_dut(another_vip_packet req);
            // Logic to start recording transaction
            //#1;
            @(negedge clk);

            // trigger for transaction recording
            drvstart = 1'b1;

            // Drive logic 
            pkt.copy(req);
            `uvm_info("ANOTHER_VIP INTERFACE", $sformatf("Driving packet to DUT:%s", pkt.convert2string()), UVM_HIGH)
            valid_data = 1'b1;
            //#1;
            @(negedge clk);

            // Reset trigger
            drvstart = 1'b0;
        endtask : send_to_dut

        // Collect Packets
        task collect_packet(another_vip_packet req);
            // Logic to start recording transaction
            //#1;
            @(posedge clk iff valid_data);
            valid_data = 1'b0;
            
            // trigger for transaction recording
            monstart = 1'b1;

            // Collect logic 
            req.copy(pkt);
            `uvm_info("ANOTHER_VIP INTERFACE", $sformatf("Collected packet:%s", req.convert2string()), UVM_HIGH)
            //#1;
            @(posedge clk);

            // Reset trigger
            monstart = 1'b0;
        endtask : collect_packet

    endinterface : another_vip_if
    