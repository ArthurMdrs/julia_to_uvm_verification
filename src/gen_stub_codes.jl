# ***********************************
# Stub Codes
# ***********************************
# Creates a stub DUT module
# ***********************************


gen_line_stub_if_signal(vec::if_field_t, tabs) = begin
    if vec.is_output == true
        return "$(tabs)output reg $(vec.range) $(vec.field_name),\n"
    else
        return "$(tabs)input      $(vec.range) $(vec.field_name),\n"
    end
end
gen_stub_if_signals(tabs) = begin
    str = ""
    uvc_names_ = uvc_names
    if using_this_clknrst == true
        uvc_names_ = filter(x -> x!= clknrst_name, uvc_names)
    end
    for uvc_name in uvc_names_
        if_sigs_vec = get_uvc_cfg_fld(uvc_name, :if_sigs_vec)
        str *= "$(tabs)// Signals from $(uvc_name)'s interface - begin\n"
        str *= gen_long_str(if_sigs_vec, tabs*"    ", gen_line_stub_if_signal)
        str = (uvc_name == uvc_names_[end]) ? str[1:end-2]*"\n" : str
        str *= "$(tabs)// Signals from $(uvc_name)'s interface - end\n"
    end
    return str
end
# gen_stub_parameters_str_file(if_vector) = 
#     "if_vector = $(if_vector)\nuvc_names = $(uvc_names)\nclk_rst_vec = $([clock_name, reset_name, rst_is_negedge_sensitive])"
# get_interface_signals() = begin
#     if_gather = []
#     for uvc_name in uvc_names
#         if_sigs_vec = get_uvc_cfg_fld(uvc_name, :if_sigs_vec)
#         append!(if_gather, if_sigs_vec)
#     end
#     return if_gather
# end

stub_gen() = begin
    if run_stub_gen == true
        # if_vector = get_interface_signals()
        
        output_file_setup("$(rtl_dir)")
        
        write_file("$(rtl_dir)/$(dut_name).sv", gen_stub_base())
        # write_file("$(rtl_dir)/$(dut_name)_parameters.jl", gen_stub_parameters_str_file(if_vector))
    end
end

gen_stub_base() = begin 
    param_str = has_paramaters ? "import $(dut_name)_params_pkg::*; " : ""
    return """
    module $(dut_name) $(param_str)$(get_param_declaration(params_vec, dut_name, "    "))(
        input $(clock_name), 
        input $(reset_name), 
    $( gen_stub_if_signals("    ")[1:end-1] )
    );

        always @(posedge $(clock_name) or $( (rst_is_negedge_sensitive) ? "negedge" : "posedge" ) $(reset_name)) begin
            if($( (rst_is_negedge_sensitive) ? "~" : "" )$(reset_name)) begin
                // Reset logic
            end
            else begin
                // Sequencial logic
            end
        end

        always @(*) begin
            // Combinational logic
        end

    endmodule : $(dut_name)
    """
end
# ****************************************************************
