# ***********************************
# Top Codes!!!!!
# ***********************************
# The top generation uses the file stub_parameters.jl
# It is required to have generated the STUB to create the stub_parameters.jl!!!!
# ***********************************

gen_line_interfaces_instances(uvc_name, tabs) = begin
    # TODO: account for different clk_rst_names and rst_is_negedge_sensitive
    cwd = pwd()
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    uvc_clock_name = clock_name
    uvc_reset_name = reset_name
    if_name = use_short_names ? short_names_dict["interface"] : "interface"
    restore_config()
    return """$(tabs)$(uvc_name)_$(if_name) if_$(uvc_name)(.$(uvc_clock_name)($(clock_name)), .$(uvc_reset_name)($(reset_name)));\n"""
end
gen_line_send_if_to_uvc(uvc_name, tabs) = begin
    cwd = pwd()
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    if_name = use_short_names ? short_names_dict["interface"] : "interface"
    restore_config()
    # return """$(tabs)uvm_config_db#($(uvc_name)_vif)::set(.cntxt(null), .inst_name("uvm_test_top"), .field_name("vif_$(uvc_name)"), .value(if_$(uvc_name)));\n"""
    return """$(tabs)uvm_config_db#(virtual interface $(uvc_name)_$(if_name))::set(.cntxt(null), .inst_name("uvm_test_top"), .field_name("vif_$(uvc_name)"), .value(if_$(uvc_name)));\n"""
end
gen_line_if_connection(signal_name, uvc_name, tabs) = 
    """$(tabs).$(signal_name[3])(if_$(uvc_name).$(signal_name[3])),\n"""
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
    include_jl("generated_files/rtl/stub_parameters.jl")
    output_file_setup("generated_files/test_top"; reset_folder=false)
    write_file("generated_files/test_top/top.sv", gen_top_base())
end

gen_top_base() = begin
    my_str = """
    `default_nettype none
    
    module top;

        import uvm_pkg::*;
        `include "uvm_macros.svh"
        
        import stub_pkg::*;

        logic $(clock_name), $(reset_name);

        // Interfaces instances - begin
    """
    my_str *= gen_clknrst ? "        clknrst_if if_clknrst();\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_line_interfaces_instances) )    // Interfaces instances - end


        stub dut(
            .$(clock_name)($(clock_name)),
            .$(reset_name)($(reset_name)),$( gen_top_if_connection_signals(if_vector, "        ") )    );

    """
    if gen_clknrst
        my_str *= """
            assign $(clock_name)   = if_clknrst.clk;
            assign $(reset_name) = if_clknrst.rst_n;
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
    my_str *= gen_clknrst ? """            uvm_config_db#(virtual interface clknrst_if)::set(.cntxt(null), .inst_name("uvm_test_top"), .field_name("vif_clknrst"), .value(if_clknrst));\n""" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "            ", gen_line_send_if_to_uvc) )        // Virtual interfaces send to UVCs - end

            run_test("random_test");
        end
        
    endmodule: top

    `default_nettype wire
    """
    return my_str
end

# ****************************************************************
