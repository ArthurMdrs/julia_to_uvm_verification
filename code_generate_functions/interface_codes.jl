# ***********************************
# Interface Codes!!!!!
# ***********************************
# Form of the vector to generate the interface:
#  [clock_name , 
#       [reset_name , is_negedge?] , 
#       [[type , length , name] , [] , [], ...] 
#       ]
# 
# E.g.:
# if_vec = ["clock_name", ["reset_name", true], signals_if_config]
# signals_if_config = [
#     ["bit"  , "[7:0]" , "addr" ],
#     ["bit"  , "[7:0]" , "data" ],
#     ["bit"  , "1"     , "bit_" ],
#     ["logic", "[12:0]", "oioi3"]]
#
# These vectors come from the file VIP_parameters/(VIP name)_parameters.jl
# ***********************************
gen_line_if_signal(vec, tabs; end_of_line=";") = 
    "$(tabs)$(vec[1]) $((vec[2]=="1") ? "     " : vec[2]) $(vec[3])$(end_of_line)\n"

gen_if_base(prefix_name, vec) = """
    interface $(prefix_name)_if (input $(vec[1]), input $(vec[2][1]) );

        import uvm_pkg::*;    
        `include "uvm_macros.svh"
        import $(prefix_name)_pkg::*;

        // Interface Signals - Begin
$(gen_long_str(vec[3], "        ", gen_line_if_signal))        // Interface Signals - End

        // Signals for transaction recording
        bit monstart, drvstart;
        
        // Signal to control monitor activity
        bit got_packet;
        // Test packet
        $(prefix_name)_packet pkt = new("PKT");

        task $(prefix_name)_reset();
            @($((vec[2][2]) ? "negedge" : "posedge") $(vec[2][1]));
            monstart = 0;
            drvstart = 0;
            disable send_to_dut;
        endtask

        // Gets a packet and drive it into the DUT
        task send_to_dut($(prefix_name)_packet req);
            // Logic to start recording transaction
            @(negedge clk);

            // trigger for transaction recording
            drvstart = 1'b1;

            // Drive logic 
            pkt.copy(req);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Driving packet to DUT:%s", pkt.convert2string()), UVM_HIGH)
            got_packet = 1'b1;
            @(negedge clk);

            // Reset trigger
            drvstart = 1'b0;
        endtask : send_to_dut

        // Collect Packets
        task collect_packet($(prefix_name)_packet req);
            // Logic to start recording transaction
            @(posedge clk iff got_packet);
            got_packet = 1'b0;
            
            // trigger for transaction recording
            monstart = 1'b1;

            // Collect logic 
            req.copy(pkt);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Collected packet:%s", req.convert2string()), UVM_HIGH)
            @(posedge clk);

            // Reset trigger
            monstart = 1'b0;
        endtask : collect_packet

    endinterface : $(prefix_name)_if
    """
# ****************************************************************
