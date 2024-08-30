# ***********************************
# Top Codes!!!!!
# ***********************************
# The top generation uses the file stub_parameters.jl
# It is required to have generated the STUB to create the stub_parameters.jl!!!!
# ***********************************

gen_line_import(uvc_name, tabs) = begin
    return """
    $(tabs)import $(uvc_name)_tdefs_pkg::*;
    $(tabs)import $(uvc_name)_pkg::*;
    """
end
gen_line_interfaces_instances(uvc_name, tabs) = begin
    cwd = pwd()
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    if_name = use_short_names ? short_names_dict["interface"] : "interface"
    return """$(tabs)$(uvc_name)_$(if_name) if_$(uvc_name)(.$(clk_rst_names[1])($(clk_rst_names[1])), .$(clk_rst_names[2][1])($(clk_rst_names[2][1])));\n"""
end
gen_line_send_if_to_uvc(uvc_name, tabs) = 
    # """$(tabs)uvm_config_db#($(uvc_name)_vif)::set(.cntxt(null), .inst_name("uvm_test_top.agent_$(uvc_name).*"), .field_name("vif"), .value(if_$(uvc_name)));\n"""
    """$(tabs)uvm_config_db#($(uvc_name)_vif)::set(.cntxt(null), .inst_name("uvm_test_top"), .field_name("vif_$(uvc_name)"), .value(if_$(uvc_name)));\n"""
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
    include("generated_files/rtl/stub_parameters.jl")
    output_file_setup("generated_files/test_top"; reset_folder=false)
    write_file("generated_files/test_top/top.sv", gen_top_base())
end

gen_top_base() = begin 
    return """
    module top;

        import uvm_pkg::*;
        `include "uvm_macros.svh"

        // UVC imports - begin
    $( gen_long_str(stub_if_names, "        ", gen_line_import) )    // UVC imports - end

        `include "tests.sv"

        bit $(clk_rst_names[1]), $(clk_rst_names[2][1]);
        bit run_clock;

        // Interfaces instances - begin
    $( gen_long_str(stub_if_names, "        ", gen_line_interfaces_instances) )    // Interfaces instances - end


        stub dut(
            .$(clk_rst_names[1])($(clk_rst_names[1])),
            .$(clk_rst_names[2][1])($(clk_rst_names[2][1])),$( gen_top_if_connection_signals(if_vector, "        ") )    );

        initial begin
            $(clk_rst_names[1]) = 0;
            $(clk_rst_names[2][1]) = $( (clk_rst_names[2][2]) ? "1" : "0" );
            #3 $(clk_rst_names[2][1]) = $( (clk_rst_names[2][2]) ? "0" : "1" );
            #3 $(clk_rst_names[2][1]) = $( (clk_rst_names[2][2]) ? "1" : "0" );
        end
        always #2 $(clk_rst_names[1])=~$(clk_rst_names[1]);

        initial begin
            \$dumpfile("dump.vcd");
            \$dumpvars;

            // Virtual interfaces send to UVCs - begin
    $( gen_long_str(stub_if_names, "            ", gen_line_send_if_to_uvc) )        // Virtual interfaces send to UVCs - end

            run_test("random_test");
        end

    endmodule: top
    """
end
# ****************************************************************
