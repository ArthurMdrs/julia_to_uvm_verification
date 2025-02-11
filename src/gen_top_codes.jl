# ***********************************
# Top Codes
# ***********************************
# Creates the tb_top module
# ***********************************

gen_line_interfaces_instances(uvc_name, tabs) = begin
    # TODO: account for different clk_rst_names and rst_is_negedge_sensitive
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    uvc_clock_name = clock_name
    uvc_reset_name = reset_name
    if_name = use_short_names ? short_names_dict["interface"] : long_names_dict["interface"]
    params_str = has_paramaters ? "#(.$(dut_name)_params($(dut_name)_params)) " : ""
    restore_config()
    return """$(tabs)$(uvc_name)_$(if_name) $(get_param_conn(tabs))$(uvc_name)_if (.$(uvc_clock_name)($(clock_name)), .$(uvc_reset_name)($(reset_name)));\n"""
end
gen_line_send_if_to_uvc(uvc_name, tabs) = begin
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    if_name = use_short_names ? short_names_dict["interface"] : long_names_dict["interface"]
    restore_config()
    # return """$(tabs)uvm_config_db#(virtual interface $(uvc_name)_$(if_name))::set(.cntxt(null), .inst_name("uvm_test_top"), .field_name("vif_$(uvc_name)"), .value($(uvc_name)_if));\n"""
    return """$(tabs)uvm_config_db#($(uvc_name)_vif_t)::set(.cntxt(null), .inst_name("uvm_test_top"), .field_name("$(uvc_name)_vif"), .value($(uvc_name)_if));\n"""
end
gen_line_if_connection(signal_name, uvc_name, tabs) = 
    """$(tabs).$(signal_name[3])($(uvc_name)_if.$(signal_name[3])),\n"""
gen_top_if_connection_signals(if_vector, tabs) = begin
    str = ""
    for x in if_vector
        str *= "\n$(tabs)// Signals from $(x[1])'s interface - begin\n"
        gen_line(signal_name, tabs) = gen_line_if_connection(signal_name, x[1], tabs)
        str *= gen_long_str(x[2], tabs*"    ", gen_line)
        str = (x == if_vector[end]) ? str[1:end-2]*"\n" : str
        str *= "$(tabs)// Signals from $(x[1])'s interface - end\n"
    end
    return str
end


top_gen() = (!run_top_gen) ? "" : begin
    include_jl("generated_files/rtl/$(dut_name)_parameters.jl")
    output_file_setup("generated_files/test_top"; reset_folder=false)
    write_file("generated_files/test_top/$(dut_name)_tb_top.sv", gen_top_base())
end

gen_top_base() = begin
    if_name = use_short_names ? short_names_dict["interface"] : long_names_dict["interface"]
    
    my_str = """
    `default_nettype none
    
    module $(dut_name)_tb_top;
        
        import uvm_pkg::*;
        `include "uvm_macros.svh"
    """
    
    if has_paramaters
        my_str *= """
            
            import $(dut_name)_params_pkg::*;
        """
    end
        
    my_str *= """
        import $(dut_name)_env_pkg::*;
    """
        
    if has_paramaters
        my_str *= """
            
            typedef $(dut_name)_test_base $(get_param_conn("    "))$(dut_name)_test_base_rplc;
            
            typedef $(dut_name)_test_random $(get_param_conn("    "))$(dut_name)_test_random_rplc;
        """
    end
    
    my_str *= """
        
        logic $(clock_name), $(reset_name);
        
    """
    my_str *= """
    
        // Virtual interface typedefs - begin
    """
    my_str *= gen_clknrst ? gen_line_vif_typedef("clknrst", "        ") : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_line_vif_typedef) )    // Virtual interface typedefs - end
    
    """
    my_str *= """

        // Interfaces instances - begin
    """
    my_str *= gen_clknrst ? "        clknrst_$(if_name) $(get_param_conn("        ")) clknrst_$(if_name)();\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_line_interfaces_instances) )    // Interfaces instances - end


        $(dut_name) dut(
            .$(clock_name)($(clock_name)),
            .$(reset_name)($(reset_name)),$( gen_top_if_connection_signals(if_vector, "        ") )    );

    """
    if gen_clknrst
        my_str *= """
            assign $(clock_name)   = clknrst_$(if_name).clk;
            assign $(reset_name) = clknrst_$(if_name).rst_n;
        """
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
    my_str *= gen_clknrst ? """            uvm_config_db#(clknrst_vif_t)::set(.cntxt(null), .inst_name("uvm_test_top"), .field_name("clknrst_vif"), .value(clknrst_$(if_name)));\n""" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "            ", gen_line_send_if_to_uvc) )        // Virtual interfaces send to UVCs - end

            run_test("$(dut_name)_test_random");
        end
        
    endmodule: $(dut_name)_tb_top

    `default_nettype wire
    """
    return my_str
end

# ****************************************************************
