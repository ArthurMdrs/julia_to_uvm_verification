# ***********************************
# Interface Codes
# ***********************************
# Creates an interface
# ***********************************

gen_line_drv_cb_sig(sig::if_field_t, tabs) = begin
    # direction_str = sig.is_output ? "output" : "input"
    direction_str = sig.is_output ? "input" : "output"
    return "$(tabs)$(direction_str) $(sig.field_name);\n"
end
gen_lines_drv_cb(vec::Vector{if_field_t}, tabs, clock_name) = begin
    my_str = """
    $(tabs)clocking drv_cb @(posedge $(clock_name));
    $(tabs)    default input #1ns output #1ns;
    $( gen_long_str(vec, tabs*"    ", gen_line_drv_cb_sig)[1:end-1] )
    $(tabs)endclocking
    """
end
gen_line_mon_cb_sig(sig::if_field_t, tabs) = begin
    return "$(tabs)input $(sig.field_name);\n"
end
gen_lines_mon_cb(vec::Vector{if_field_t}, tabs, clock_name) = begin
    my_str = """
    $(tabs)clocking mon_cb @(posedge $(clock_name));
    $(tabs)    default input #1ns output #5ns;
    $( gen_long_str(vec, tabs*"    ", gen_line_mon_cb_sig)[1:end-1] )
    $(tabs)endclocking
    """
end

    # TODO: USE CLOCKING BLOCKS!!
gen_if_base(prefix_name) = begin 
    if_name = get_uvc_cfg_fld(prefix_name, :class_names)["interface"]
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    clock_name = get_uvc_cfg_fld(prefix_name, :clock_name)
    reset_name = get_uvc_cfg_fld(prefix_name, :reset_name)
    rst_is_negedge_sensitive = get_uvc_cfg_fld(prefix_name, :rst_is_negedge_sensitive)
    if_sigs_vec = get_uvc_cfg_fld(prefix_name, :if_sigs_vec)
    param_str = has_paramaters ? "import $(dut_name)_params_pkg::$(dut_name)_params_t;\n$(get_param_declaration(params_vec, dut_name, "    "))" : ""
    return """
    interface $(prefix_name)_$(if_name) $(param_str)(
        input logic $(clock_name), 
        input logic $(reset_name)
    );
        
        import uvm_pkg::*;
        `include "uvm_macros.svh"
        
        import $(prefix_name)_pkg::*;
        
        // Interface Signals - Begin
    $( gen_long_str(if_sigs_vec, "    ", gen_line_if_signal)[1:end-1] )
        // Interface Signals - End
        
    $(gen_lines_drv_cb(if_sigs_vec, "    ", clock_name)[1:end-1])
        
    $(gen_lines_mon_cb(if_sigs_vec, "    ", clock_name)[1:end-1])
        
        // Signals for transaction recording
        bit monstart, drvstart;
        
        // Signal to control monitor activity
        bit got_tr;
        
        // Test transaction
        //$(prefix_name)_$(tr_name) tr = new("TR");
        
        typedef $(prefix_name)_$(tr_name) $(get_param_conn(dut_name, "    "))$(prefix_name)_$(tr_name)_t;
        
        $(prefix_name)_$(tr_name)_t tr = new("TR");
        
        task $(prefix_name)_reset();
            @($((rst_is_negedge_sensitive) ? "negedge" : "posedge") $(reset_name));
            monstart = 0;
            drvstart = 0;
            disable send_to_dut;
        endtask
        
        // Gets a transaction and drive it into the DUT
        task send_to_dut ($(prefix_name)_$(tr_name)_t req);
            // Logic to start recording transaction
            @(negedge $(clock_name));
            
            // trigger for transaction recording
            drvstart = 1'b1;
            
            // Drive logic 
            tr.copy(req);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Driving transaction to DUT:%s", tr.convert2string()), UVM_HIGH)
            got_tr = 1'b1;
            @(negedge $(clock_name));
            
            // Reset trigger
            drvstart = 1'b0;
        endtask : send_to_dut
        
        // Collect transactions
        task collect_tr ($(prefix_name)_$(tr_name)_t req);
            // Logic to start recording transaction
            @(posedge $(clock_name) iff got_tr);
            got_tr = 1'b0;
            
            // trigger for transaction recording
            monstart = 1'b1;
            
            // Collect logic 
            req.copy(tr);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Collected transaction:%s", req.convert2string()), UVM_HIGH)
            @(posedge $(clock_name));
            
            // Reset trigger
            monstart = 1'b0;
        endtask : collect_tr
        
    endinterface : $(prefix_name)_$(if_name)
    """
end

gen_clknrst_if(prefix_name) = begin
    if_name = get_uvc_cfg_fld(prefix_name, :class_names)["interface"]
    clock_name = get_uvc_cfg_fld(prefix_name, :clock_name)
    reset_name = get_uvc_cfg_fld(prefix_name, :reset_name)
    param_str = has_paramaters ? "import $(dut_name)_params_pkg::$(dut_name)_params_t;\n$(get_param_declaration(params_vec, dut_name, "    "))" : ""
    return """
    interface $(prefix_name)_$(if_name) $(param_str)(
        output logic $(clock_name), 
        output logic $(reset_name)
    );
        
        import uvm_pkg::*;    
        `include "uvm_macros.svh"
        import $(prefix_name)_pkg::*;
        
        // logic $(clock_name);
        // logic $(reset_name);
        
        realtime clk_period = 10ns;
        bit      clk_active;
        
        // Generate clock
        initial begin
            wait (clk_active);
            forever begin
                #(clk_period/2);
                if (clk_active) begin
                    case ($(clock_name))
                    1'b0: $(clock_name) = 1'b1;
                    1'b1: $(clock_name) = 1'b0;
                    1'bx: $(clock_name) = 1'b0;
                    endcase
                end
            end
        end
        
        function void set_period (realtime new_clk_period);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Changing clock period to %0t", new_clk_period), UVM_LOW)
            clk_period = new_clk_period;
        endfunction : set_period
        
        function void start_clk ();
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", "Starting clock generation", UVM_HIGH)
            if (clk_period != 0ns)
                clk_active = 1;
        endfunction : start_clk
        
        task stop_clk ();
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", "Stopping clock generation", UVM_HIGH)
            wait ($(clock_name) == 1'b0);
            clk_active = 0;
        endtask : stop_clk
        
        function void set_clk_val (logic new_clk_val);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Changing clock value to %b", new_clk_val), UVM_HIGH)
            $(clock_name) = new_clk_val;
        endfunction : set_clk_val
        
        function void set_rst_val (logic new_rst_val);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Changing reset value to %b", new_rst_val), UVM_HIGH)
            $(reset_name) = new_rst_val;
        endfunction : set_rst_val
        
        task assert_rst (int unsigned rst_assert_duration);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", \$sformatf("Asserting reset for %0t", (rst_assert_duration * 1ps)), UVM_MEDIUM)
            $(reset_name) = 1'b0;
            #(rst_assert_duration * 1ps);
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", "De-asserting reset", UVM_MEDIUM)
            $(reset_name) = 1'b1;
        endtask : assert_rst
        
        task wait_clk_posedge ();
            @(posedge $(clock_name));
        endtask : wait_clk_posedge
        
        task wait_clk_negedge ();
            @(negedge $(clock_name));
        endtask : wait_clk_negedge

    endinterface : $(prefix_name)_$(if_name)
    """
end
    
# ****************************************************************
