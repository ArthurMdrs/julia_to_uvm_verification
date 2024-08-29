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

gen_if_base(prefix_name, vec) = begin 
    name = use_short_names ? short_names_dict["interface"] : "interface"
    tr_name = use_short_names ? short_names_dict["transaction"] : "transaction"
    return """
    interface $(prefix_name)_$(name) (input $(vec[1]), input $(vec[2][1]));

        import uvm_pkg::*;    
        `include "uvm_macros.svh"
        import $(prefix_name)_pkg::*;

        // Interface Signals - Begin
    $(gen_long_str(vec[3], "    ", gen_line_if_signal))    // Interface Signals - End

        // Signals for transaction recording
        bit monstart, drvstart;
        
        // Signal to control monitor activity
        bit got_tr;
        // Test transaction
        $(prefix_name)_$(tr_name) tr = new("TR");

        task $(prefix_name)_reset();
            @($((vec[2][2]) ? "negedge" : "posedge") $(vec[2][1]));
            monstart = 0;
            drvstart = 0;
            disable send_to_dut;
        endtask

        // Gets a transaction and drive it into the DUT
        task send_to_dut($(prefix_name)_$(tr_name) req);
            // Logic to start recording transaction
            @(negedge clk);

            // trigger for transaction recording
            drvstart = 1'b1;

            // Drive logic 
            tr.copy(req);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Driving transaction to DUT:%s", tr.convert2string()), UVM_HIGH)
            got_tr = 1'b1;
            @(negedge clk);

            // Reset trigger
            drvstart = 1'b0;
        endtask : send_to_dut

        // Collect transactions
        task collect_tr($(prefix_name)_$(tr_name) req);
            // Logic to start recording transaction
            @(posedge clk iff got_tr);
            got_tr = 1'b0;
            
            // trigger for transaction recording
            monstart = 1'b1;

            // Collect logic 
            req.copy(tr);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Collected transaction:%s", req.convert2string()), UVM_HIGH)
            @(posedge clk);

            // Reset trigger
            monstart = 1'b0;
        endtask : collect_tr

    endinterface : $(prefix_name)_$(name)
    """
end
# ****************************************************************
