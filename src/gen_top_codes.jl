# ***********************************
# Top Codes
# ***********************************
# Creates the tb_top module
# ***********************************

gen_line_interfaces_instances(uvc_name, tabs) = begin
    uvc_clock_name = get_uvc_cfg_fld(uvc_name, :clock_name )
    uvc_reset_name = get_uvc_cfg_fld(uvc_name, :reset_name )
    if_name        = get_uvc_cfg_fld(uvc_name, :class_names)["interface"]
    params_str = has_parameters ? "#(.$(dut_name)_params($(dut_name)_params)) " : ""
    return """$(tabs)$(uvc_name)_$(if_name) $(get_param_conn(dut_name, tabs))$(uvc_name)_if (.$(uvc_clock_name)($(clock_name)), .$(uvc_reset_name)($(reset_name)));\n"""
end
gen_line_send_if_to_uvc(uvc_name, tabs) = begin
    if_name = get_uvc_cfg_fld(uvc_name, :class_names)["interface"]
    # return """$(tabs)uvm_config_db#(virtual interface $(uvc_name)_$(if_name))::set(.cntxt(null), .inst_name("uvm_test_top"), .field_name("vif_$(uvc_name)"), .value($(uvc_name)_if));\n"""
    return """$(tabs)uvm_config_db#($(uvc_name)_vif_t)::set(.cntxt(null), .inst_name("uvm_test_top"), .field_name("$(uvc_name)_vif"), .value($(uvc_name)_if));\n"""
end
gen_line_if_connection(signal_name, uvc_name, tabs) = begin
    return """$(tabs).$(signal_name)($(uvc_name)_if.$(signal_name)),\n"""
end
gen_top_if_connection_signals(tabs) = begin
    str = ""
    uvc_names_ = uvc_names
    if using_this_clknrst
        uvc_names_ = filter(x -> x!= clknrst_name, uvc_names)
    end
    for uvc_name in uvc_names_
        if_sigs_vec = get_uvc_cfg_fld(uvc_name, :if_sigs_vec)
        str *= "\n$(tabs)// Signals from $(uvc_name)'s interface - begin\n"
        gen_line(signal_vec, tabs) = gen_line_if_connection(signal_vec.field_name, uvc_name, tabs)
        str *= gen_long_str(if_sigs_vec, tabs*"    ", gen_line)
        str = (uvc_name == uvc_names_[end]) ? str[1:end-2]*"\n" : str
        str *= "$(tabs)// Signals from $(uvc_name)'s interface - end\n"
    end
    return str
end


top_gen() = begin
    if run_top_gen == true
        output_file_setup("$(tb_top_dir)"; reset_folder=false)
        write_file("$(tb_top_dir)/$(dut_name)_tb_top.sv", gen_top_base())
        write_file("$(tb_top_dir)/$(dut_name)_tb_pkg.sv", gen_tb_pkg())
    end
end

gen_top_base() = begin
    if_name = class_names["interface"]
    
    my_str = """
    `default_nettype none
    
    module $(dut_name)_tb_top;
        
        import uvm_pkg::*;
        `include "uvm_macros.svh"
        
    """
    
    if has_parameters
        my_str *= """
            import $(dut_name)_params_pkg::*;
        """
    end
        
    my_str *= """
        import $(dut_name)_tb_pkg::*;
    """
        
    if has_parameters
        my_str *= """
            
            typedef $(dut_name)_test_base $(get_param_conn(dut_name, "    "))$(dut_name)_test_base_rplc;
            
            typedef $(dut_name)_test_random $(get_param_conn(dut_name, "    "))$(dut_name)_test_random_rplc;
            
        """
    end
    
    my_str *= """
        
        logic $(clock_name), $(reset_name);
        
        
        // Virtual interface typedefs - begin
    """
    my_str *= """
    $( gen_long_str(uvc_names, "        ", gen_line_vif_typedef)[1:end-1] )
        // Virtual interface typedefs - end
        
        
        // Interfaces instances - begin
    """
    my_str *= """
    $( gen_long_str(uvc_names, "        ", gen_line_interfaces_instances)[1:end-1] )
        // Interfaces instances - end
        
        
        $(dut_name) $(get_param_conn(dut_name, "    "))dut (
            .$(clock_name)($(clock_name)),
            .$(reset_name)($(reset_name)),$( gen_top_if_connection_signals("        ")[1:end-1] )
        );
        
    """
    if using_this_clknrst
        # my_str *= """
        #     assign $(clock_name) = $(clknrst_name)_$(if_name).$(get_uvc_cfg_fld(clknrst_name, :clock_name));
        #     assign $(reset_name) = $(clknrst_name)_$(if_name).$(get_uvc_cfg_fld(clknrst_name, :reset_name));
        # """
    else
        my_str *= """
            initial begin
                $(clock_name) = 0;
                $(reset_name) = $( (rst_is_negedge_sensitive) ? "1" : "0" );
                #3 $(reset_name) = $( (rst_is_negedge_sensitive) ? "0" : "1" );
                #3 $(reset_name) = $( (rst_is_negedge_sensitive) ? "1" : "0" );
            end
            always #2 $(clock_name)=~$(clock_name);
        """
    end
    my_str *= """
        
        initial begin
            \$timeformat(-9, 3, "ns", 12); // e.g.: "   900.000ns"
            \$dumpfile("dump.vcd");
            \$dumpvars;
            
            // Virtual interfaces send to UVCs - begin
    """
    my_str *= """
    $( gen_long_str(uvc_names, "            ", gen_line_send_if_to_uvc)[1:end-1] )
            // Virtual interfaces send to UVCs - end
            
            run_test("$(dut_name)_test_random");
        end
        
    endmodule : $(dut_name)_tb_top
    
    `default_nettype wire
    """
    return my_str
end

# ****************************************************************

gen_tb_pkg() = begin
    my_str = """
    package $(dut_name)_tb_pkg;
        
        import uvm_pkg::*;
        `include "uvm_macros.svh"
        
    """
    my_str *= has_parameters ? gen_line_import("$(dut_name)_params", "    ")*"    \n" : ""
    my_str *= """
    $( gen_long_str(uvc_names, "    ", gen_line_import_tdefs)[1:end-1] )
        
    $( gen_long_str(uvc_names, "    ", gen_line_import)[1:end-1] )
        
    $( gen_line_import("$(dut_name)_env", "    ")[1:end-1] )
        
        `include "$(dut_name)_test_base.sv"
        `include "$(dut_name)_test_random.sv"
        
    endpackage: $(dut_name)_tb_pkg
    """
    return my_str
end

# ****************************************************************
