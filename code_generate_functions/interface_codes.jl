# ***********************************
# Interface Codes!!!!!
# ***********************************
# Forma do vetor para gerar a interface:
#  [clock_name , 
#       [reset_name , is_negedge?] , 
#       [[type , length , name] , [] , [], ...] 
#       ]
# 
# Ex:
# if_vec = ["clock_name", ["reset_name", true], signals_if_config]
# signals_if_config = [
#     ["bit"  , "[7:0]" , "addr" ],
#     ["bit"  , "[7:0]" , "data" ],
#     ["bit"  , "1"     , "bit_" ],
#     ["logic", "[12:0]", "oioi3"]]
#
# Esses vetores vem do arquivo VIP_parameters/(VIP name)_parameters.jl
# ***********************************
gen_line_if_signal(vec, tabs; end_of_line=";") = 
    "$(tabs)$(vec[1]) $((vec[2]=="1") ? "     " : vec[2]) $(vec[3])$(end_of_line)\n"

gen_if_base(prefix_name, vec) = """
    interface $(prefix_name)_if (input $(vec[1]), input $(vec[2][1]) );

        import uvm_pkg::*;    
        `include "uvm_macros.svh"
        import $(prefix_name)_pkg::*;

        // Interface Signals - Begin
    $(gen_long_str(vec[3], "    ", gen_line_if_signal))    // Interface Signals - End

        // signal for transaction recording
        bit monstart, drvstart;

        task $(prefix_name)_reset();
            @($((vec[2][2]) ? "negedge" : "posedge") $(vec[2][1]));
            monstart = 0;
            drvstart = 0;
            disable send_to_dut;
        endtask

        // Gets a packet and drive it into the DUT
        task send_to_dut($(prefix_name)_packet req);
            // Logic to start recording transaction

            // trigger for transaction recording
            #1;
            drvstart = 1'b1;

            // Driver logic 
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", req.convert2string(), UVM_HIGH)

            // Reset trigger
            drvstart = 1'b0;
        endtask : send_to_dut

        // Collect Packets
        task collect_packet($(prefix_name)_packet req);
            // Logic to start recording transaction

            // trigger for transaction recording
            monstart = 1'b1;

            // Driver logic 

            // Reset trigger
            monstart = 1'b0;
        endtask : collect_packet

    endinterface : $(prefix_name)_if
    """
# ****************************************************************