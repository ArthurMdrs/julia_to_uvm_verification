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
gen_line_sqr_instance(uvc_name, tabs) = begin
    sqr_name = get_uvc_cfg_fld(uvc_name, :class_names)["sequencer"]
    my_str = "$(tabs)$(uvc_name)_$(sqr_name)_t m_$(uvc_name)_$(sqr_name);\n"
    return my_str
end
gen_line_stop_seq(uvc_name, tabs) = begin
    sqr_name = get_uvc_cfg_fld(uvc_name, :class_names)["sequencer"]
    cfg_name = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    my_str = """
    $(tabs)if ($(config_inst_convention).has_$(uvc_name)_agent && $(config_inst_convention).m_$(uvc_name)_$(cfg_name).is_active)
    $(tabs)    m_$(uvc_name)_$(sqr_name).stop_sequences();
    """
    return my_str
end

gen_vsequencer() = begin
    vsqr_name = class_names["vsequencer"]
    sqr_name  = class_names["sequencer" ]
    cfg_name  = class_names["config"    ]
    
    params_prefix = get_uvc_params_prefix(dut_name)
    
    my_str = """
    class $(dut_name)_$(vsqr_name) $(get_vsqr_param_declaration("    "))extends uvm_sequencer;
        
    """
    
    if env_has_params
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
    $(gen_lines_tdefs_w_param_env(params_prefix, "$(dut_name)_env_$(cfg_name)", "    ")[1:end-1])
    """
    
    for uvc_name in uvc_names
        sqr_name = get_uvc_cfg_fld(uvc_name, :class_names)["sequencer"]
        my_str *= gen_lines_tdefs_w_param_w_seq_item_env("$(uvc_name)_$(sqr_name)", uvc_name, "    ")
    end
    
    my_str *= """
        // Typedefs - end    
        
        // Sequencers - begin
    $( gen_long_str(uvc_names, "    ", gen_line_sqr_instance)[1:end-1] )
        // Sequencers - end
        
        // Env config
        $(dut_name)_env_$(cfg_name)_t $(config_inst_convention);
        
        function new(string name="$(dut_name)_$(vsqr_name)", uvm_component parent = null);
            super.new(name, parent);
        endfunction : new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if ($(config_inst_convention) == null)
                `uvm_fatal("$(uppercase(dut_name)) VSEQUENCER", "No configuration object was set!")
        endfunction : build_phase
        
    """
    
    if reset_mechanism == reset_phase_reset
        my_str *= """
            task pre_reset_phase(uvm_phase phase);
        $( gen_long_str(uvc_names, "        ", gen_line_stop_seq)[1:end-1] )
            endtask : pre_reset_phase
            
            task post_reset_phase(uvm_phase phase);
        $( gen_long_str(uvc_names, "        ", gen_line_stop_seq)[1:end-1] )
            endtask : post_reset_phase
            
        """
    end
    
        my_str *= """
    endclass : $(dut_name)_$(vsqr_name)
    """
    return my_str
end
