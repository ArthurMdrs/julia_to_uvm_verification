# ***********************************
# Interface Codes
# ***********************************
# Creates an interface
# The gen_if_base function needs a vector as an argument
# Form of the vector to generate the interface:
#  [clock_name , 
#       [reset_name , is_negedge?] , 
#       [[type , length , name] , [] , [], ...] 
#       ]
# 
# E.g.:
# if_vec = ["clock_name", ["reset_name", true], signals_if_config]
# signals_if_config = [
#     ["bit"  , "[7:0]" , "addr" , true ],
#     ["bit"  , "[7:0]" , "data" , true ],
#     ["bit"  , "1"     , "bit_" , false],
#     ["logic", "[12:0]", "oioi3", false]]
#
# These vectors come from the file UVC_parameters/(UVC name)_parameters.jl
# ***********************************
gen_line_if_signal(vec, tabs; end_of_line=";") = begin
    return "$(tabs)$(vec[1]) $((vec[2]=="1") ? "     " : vec[2]) $(vec[3])$(end_of_line)\n"
end
gen_line_drv_cb_sig(sig, tabs) = begin
    direction_str = sig[4] ? "input" : "output"
    return "$(tabs)$(direction_str) $(sig[3]);\n"
end
gen_lines_drv_cb(vec, tabs) = begin
    my_str = """
    $(tabs)clocking drv_cb @(posedge $(vec[1]));
    $(tabs)    default input #1ns output #1ns;
    $( gen_long_str(vec[3], tabs*"    ", gen_line_drv_cb_sig)[1:end-1] )
    $(tabs)endclocking
    """
end
gen_line_mon_cb_sig(sig, tabs) = begin
    return "$(tabs)input $(sig[3]);\n"
end
gen_lines_mon_cb(vec, tabs) = begin
    my_str = """
    $(tabs)clocking mon_cb @(posedge $(vec[1]));
    $(tabs)    default input #1ns output #5ns;
    $( gen_long_str(vec[3], tabs*"    ", gen_line_mon_cb_sig)[1:end-1] )
    $(tabs)endclocking
    """
end

    # TODO: USE CLOCKING BLOCKS!!
gen_if_base(prefix_name, vec) = begin 
    if_name = use_short_names ? short_names_dict["interface"] : long_names_dict["interface"]
    tr_name = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
    param_str = has_paramaters ? "import $(dut_name)_params_pkg::$(dut_name)_params_t;\n$(get_param_declaration(params_vec, dut_name, "")) " : ""
    return """
    interface $(prefix_name)_$(if_name) $(param_str)(
        input logic $(vec[1]), 
        input logic $(vec[2][1])
    );
        
        import uvm_pkg::*;
        `include "uvm_macros.svh"
        
        import $(prefix_name)_pkg::*;
        
        // Interface Signals - Begin
    $( gen_long_str(vec[3], "    ", gen_line_if_signal)[1:end-1] )
        // Interface Signals - End
        
    $(gen_lines_drv_cb(vec, "    ")[1:end-1])
        
    $(gen_lines_mon_cb(vec, "    ")[1:end-1])
        
        // Signals for transaction recording
        bit monstart, drvstart;
        
        // Signal to control monitor activity
        bit got_tr;
        
        // Test transaction
        //$(prefix_name)_$(tr_name) tr = new("TR");
        
        typedef $(prefix_name)_$(tr_name) $(get_param_conn("    "))$(prefix_name)_$(tr_name)_t;
        
        $(prefix_name)_$(tr_name)_t tr = new("TR");
        
        task $(prefix_name)_reset();
            @($((vec[2][2]) ? "negedge" : "posedge") $(vec[2][1]));
            monstart = 0;
            drvstart = 0;
            disable send_to_dut;
        endtask
        
        // Gets a transaction and drive it into the DUT
        task send_to_dut($(prefix_name)_$(tr_name)_t req);
            // Logic to start recording transaction
            @(negedge $(vec[1]));
            
            // trigger for transaction recording
            drvstart = 1'b1;
            
            // Drive logic 
            tr.copy(req);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Driving transaction to DUT:%s", tr.convert2string()), UVM_HIGH)
            got_tr = 1'b1;
            @(negedge $(vec[1]));
            
            // Reset trigger
            drvstart = 1'b0;
        endtask : send_to_dut
        
        // Collect transactions
        task collect_tr($(prefix_name)_$(tr_name)_t req);
            // Logic to start recording transaction
            @(posedge $(vec[1]) iff got_tr);
            got_tr = 1'b0;
            
            // trigger for transaction recording
            monstart = 1'b1;
            
            // Collect logic 
            req.copy(tr);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Collected transaction:%s", req.convert2string()), UVM_HIGH)
            @(posedge $(vec[1]));
            
            // Reset trigger
            monstart = 1'b0;
        endtask : collect_tr
        
    endinterface : $(prefix_name)_$(if_name)
    """
end

gen_clknrst_if() = begin
    prefix_name = "clknrst"
    if_name = use_short_names ? short_names_dict["interface"] : long_names_dict["interface"]
    param_str = has_paramaters ? "import $(dut_name)_params_pkg::$(dut_name)_params_t;\n$(get_param_declaration(params_vec, dut_name, "")) " : ""
    return """
    interface $(prefix_name)_$(if_name) $(param_str)();
        
        import uvm_pkg::*;    
        `include "uvm_macros.svh"
        import $(prefix_name)_pkg::*;
        
        logic clk;
        logic rst_n;
        
        realtime clk_period = 10ns;
        bit      clk_active;
        
        // Generate clock
        initial begin
            wait (clk_active);
            forever begin
                #(clk_period/2);
                if (clk_active) begin
                    case (clk)
                    1'b0: clk = 1'b1;
                    1'b1: clk = 1'b0;
                    1'bx: clk = 1'b0;
                    endcase
                end
            end
        end
        
        function void set_period(realtime new_clk_period);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Changing clock period to %0t", new_clk_period), UVM_LOW)
            clk_period = new_clk_period;
        endfunction : set_period
        
        function void start_clk();
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", "Starting clock generation", UVM_HIGH)
            if (clk_period != 0ns)
                clk_active = 1;
        endfunction : start_clk
        
        task stop_clk();
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", "Stopping clock generation", UVM_HIGH)
            wait (clk == 1'b0);
            clk_active = 0;
        endtask : stop_clk
        
        function void set_clk_val(logic new_clk_val);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Changing clock value to %b", new_clk_val), UVM_HIGH)
            clk = new_clk_val;
        endfunction : set_clk_val
        
        function void set_rst_val(logic new_rst_val);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Changing reset value to %b", new_rst_val), UVM_HIGH)
            rst_n = new_rst_val;
        endfunction : set_rst_val
        
        task assert_rst(int unsigned rst_assert_duration);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Asserting reset for %0t", (rst_assert_duration * 1ps)), UVM_MEDIUM)
            rst_n = 1'b0;
            #(rst_assert_duration * 1ps);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", "De-asserting reset", UVM_MEDIUM)
            rst_n = 1'b1;
        endtask : assert_rst
        
        task wait_clk_posedge();
            @(posedge clk);
        endtask : wait_clk_posedge
        
        task wait_clk_negedge();
            @(negedge clk);
        endtask : wait_clk_negedge

    endinterface : $(prefix_name)_$(if_name)
    """
end
    
# ****************************************************************
