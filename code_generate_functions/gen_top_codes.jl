# ***********************************
# Top Codes!!!!!
# ***********************************
# A geração do top usa o arquivo stub_parameters.jl
# É necessário ter gerado o STUB para gerar o arquivo stub_parameters.jl!!!!
# ***********************************

# OBS.: Algumas funções vem de outros arquivos
# A função output_file_setup() vem de uvc_gen_codes.jl
# A função write_file() vem de uvc_gen_codes.jl
gen_line_import(vip_name, tabs) = """$(tabs)import $(vip_name)_pkg::*;\n"""
gen_line_interfaces_instances(vip_name, tabs) = 
    """$(tabs)$(vip_name)_if vif_$(vip_name)(.$(clk_rst_names[1])($(clk_rst_names[1])), .$(clk_rst_names[2][1])($(clk_rst_names[2][1])));\n"""
gen_line_send_if_to_vip(vip_name, tabs) = 
    """$(tabs)$(vip_name)_vif_config::set(null,"uvm_test_top.agent_$(vip_name).*","vif",vif_$(vip_name));\n"""
gen_line_if_connection(signal_name, vip_name, tabs) = 
    """$(tabs).$(signal_name[3])(vif_$(vip_name).$(signal_name[3])),\n"""
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

gen_top_base() = """
    module top;

        import uvm_pkg::*;
        `include "uvm_macros.svh"

        // VIP imports - begin
    $( gen_long_str(stub_if_names, "        ", gen_line_import) )    // VIP imports - end

        `include "tests.sv"

        bit $(clk_rst_names[1]), $(clk_rst_names[2][1]);
        bit run_clock;

        // Virtual interfaces instances - begin
    $( gen_long_str(stub_if_names, "        ", gen_line_interfaces_instances) )    // Virtual interfaces instances - end


        stub dut(
            .$(clk_rst_names[1])($(clk_rst_names[1])),
            .$(clk_rst_names[2][1])($(clk_rst_names[2][1])),$( gen_top_if_connection_signals(if_vector, "        ") )        );

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

            // Virtual interfaces send to VIPs - begin
    $( gen_long_str(stub_if_names, "            ", gen_line_send_if_to_vip) )        // Virtual interfaces send to VIPs - end

            run_test("random_test");
        end

    endmodule: top
    """
# ****************************************************************