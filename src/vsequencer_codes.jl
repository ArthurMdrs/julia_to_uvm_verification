# ***********************************
# Virtual Sequencer Codes
# ***********************************
# Creates a virtual sequencer to be added to the environment
# ***********************************

gen_line_seq_item_t_decl(uvc_name, tabs) = begin
    tr_name = get_uvc_cfg_fld(uvc_name, :class_names)["transaction"]
    my_str = "$(tabs)parameter type $(uvc_name)_$(tr_name)_t = uvm_sequence_item,\n"
    return my_str
end
get_vsqr_param_declaration(tabs) = begin
    my_str = ""
    if has_paramaters
        gen_line(param_vec, tabs) = "$(tabs)$(param_vec.name): $(param_vec.default_val),\n"
        my_str *= """
        #(
        $( gen_long_str(uvc_names, tabs, gen_line_seq_item_t_decl)[1:end-1] )
        $(tabs)parameter $(dut_name)_params_t $(dut_name)_params = '0
        ) """
    end
    return my_str
end
get_vsqr_param_conn(tabs) = begin
    if has_paramaters
        my_str = """
        #(
        $( gen_long_str(uvc_names, tabs*"    ", gen_line_seq_item_t_conn)[1:end-1] )
        $(tabs)    .$(dut_name)_params($(dut_name)_params)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end
gen_line_sqr_instance(sqr_name, tabs) = begin
    my_str = "$(tabs)$(sqr_name)_t m_$(sqr_name);\n"
    return my_str
end
gen_line_stop_seq(sqr_name, tabs) = begin
    my_str = "$(tabs)m_$(sqr_name).stop_sequences();\n"
    return my_str
end

gen_vsequencer() = begin
    vsqr_name = class_names["vsequencer"]
    sqr_name  = class_names["sequencer" ]
    cfg_name  = class_names["config"    ]
    my_str = """
    class $(dut_name)_$(vsqr_name) $(get_vsqr_param_declaration("    "))extends uvm_sequencer;
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_component_param_utils($(dut_name)_$(vsqr_name) $(get_vsqr_param_conn("    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(dut_name)_$(vsqr_name))
        """
    end
    
    my_str *= """
        
        // Typedefs - begin
    $(gen_lines_tdefs_w_param("$(dut_name)_env_$(cfg_name)", "    ")[1:end-1])
    """
    
    sequencer_list = []
    for uvc_name in uvc_names
        sqr_name = get_uvc_cfg_fld(uvc_name, :class_names)["sequencer"]
        my_str *= gen_lines_tdefs_w_param_w_seq_item("$(uvc_name)_$(sqr_name)", uvc_name, "    ")
        push!(sequencer_list, "$(uvc_name)_$(sqr_name)")
    end
    
    my_str *= """
        // Typedefs - end    
        
        // Sequencers - begin
    $( gen_long_str(sequencer_list, "    ", gen_line_sqr_instance)[1:end-1] )
        // Sequencers - end
        
        // Env config
        $(dut_name)_env_$(cfg_name)_t $(config_inst_convention);
        
        function new(string name="$(dut_name)_$(vsqr_name)", uvm_component parent = null);
            super.new(name, parent);
        endfunction : new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if(uvm_config_db#($(dut_name)_env_$(cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("$(config_inst_convention)"), .value($(config_inst_convention))))
                `uvm_info("$(uppercase(dut_name))) VSEQUENCER", "Configuration object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(dut_name))) VSEQUENCER", "No configuration object was set!")
        endfunction : build_phase

        task pre_reset_phase(uvm_phase phase);
    $( gen_long_str(sequencer_list, "        ", gen_line_stop_seq)[1:end-1] )
        endtask : pre_reset_phase

        task post_reset_phase(uvm_phase phase);
    $( gen_long_str(sequencer_list, "        ", gen_line_stop_seq)[1:end-1] )
        endtask : post_reset_phase

    endclass : $(dut_name)_$(vsqr_name)
    """
    return my_str
end
