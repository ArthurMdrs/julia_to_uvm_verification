# ***********************************
# Virtual Sequence Lib Codes
# ***********************************
# Creates a virtual sequence library to be used by the virtual sequencer
# ***********************************

gen_line_seq_instance(seq_name, tabs) = begin
    my_str = "$(tabs)$(seq_name)_t m_$(seq_name);\n"
    return my_str
end
gen_line_rnd_seq_creation(uvc_name, tabs) = begin
    seq_name = get_uvc_cfg_fld(uvc_name, :class_names)["sequence"]
    my_str = "$(tabs)m_$(uvc_name)_random_$(seq_name) = $(uvc_name)_random_$(seq_name)_t::type_id::create(\"m_$(uvc_name)_random_$(seq_name)\");\n"
    return my_str
end
gen_line_rnd_seq_set_phase(uvc_name, tabs) = begin
    seq_name = get_uvc_cfg_fld(uvc_name, :class_names)["sequence"]
    my_str = "$(tabs)m_$(uvc_name)_random_$(seq_name).set_starting_phase(get_starting_phase());\n"
    return my_str
end
gen_rnd_seq_setup(uvc_name, tabs) = begin
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "agent_" * get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    else
        cfg_name = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    end
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        env_cfg_name = "env_$(class_names["config"])"
    else
        env_cfg_name = "$(class_names["config"])"
    end
    my_str = """
    $(tabs)if (m_$(env_cfg_name).has_$(uvc_name)_agent) begin
    $( gen_line_rnd_seq_creation(uvc_name, tabs*"    ")[1:end-1] )
    $( gen_line_rnd_seq_set_phase(uvc_name, tabs*"    ")[1:end-1] )
    $(tabs)end
    """
    return my_str
end
gen_line_rnd_seq_start(uvc_name, tabs) = begin
    sqr_name = get_uvc_cfg_fld(uvc_name, :class_names)["sequencer"]
    seq_name = get_uvc_cfg_fld(uvc_name, :class_names)["sequence" ]
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "agent_" * get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    else
        cfg_name = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    end
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        env_cfg_name = "env_$(class_names["config"])"
    else
        env_cfg_name = "$(class_names["config"])"
    end
    my_str = """
    $(tabs)if (m_$(env_cfg_name).has_$(uvc_name)_agent) begin
    $(tabs)    if (m_$(env_cfg_name).m_$(uvc_name)_$(cfg_name).is_active) begin
    $( gen_line_rnd_seq_creation(uvc_name, tabs*"        ")[1:end-1] )
    $( gen_line_rnd_seq_set_phase(uvc_name, tabs*"        ")[1:end-1] )
    $(tabs)        m_$(uvc_name)_random_$(seq_name).start(.sequencer(p_sequencer.m_$(uvc_name)_$(sqr_name)), .call_pre_post(0));
    $(tabs)    end
    $(tabs)end
    """
    return my_str
end

gen_vseq_base() = begin
    vsqr_name = class_names["vsequencer"]
    sqr_name  = class_names["sequencer" ]
    vseq_name = class_names["vsequence" ]
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "env_$(class_names["config"])"
    else
        cfg_name = "$(class_names["config"])"
    end
    
    params_prefix = get_uvc_params_prefix(dut_name)
    
    my_str = """
    class $(dut_name)_base_$(vseq_name) $(get_vsqr_param_declaration("    "))extends uvm_sequence;
        
    """
    
    if env_has_params
        my_str *= """
            `uvm_object_param_utils($(dut_name)_base_$(vseq_name) $(get_vsqr_param_conn("    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_object_utils($(dut_name)_base_$(vseq_name))
        """
    end
    
    my_str *= """
        
        // Typedefs - begin
    $( gen_lines_tdefs_w_param_env(params_prefix, "$(dut_name)_$(cfg_name)", "    ")[1:end-1] )
    """
    
    seq_list = []
    if using_this_clknrst == true
        seq_name = get_uvc_cfg_fld(clknrst_name, :class_names)["sequence"]
        for x in clknrst_actions_vec
            push!(seq_list, clknrst_name*"_"*x*"_$(seq_name)")
        end
        push!(seq_list, "$(clknrst_name)_reset_and_start_clk_$(seq_name)")
    end
    for x in seq_list
        my_str *= gen_lines_tdefs_w_param_w_seq_item_env(x, clknrst_name, "    ")
    end
    for uvc_name in uvc_names
        if uvc_name == clknrst_name && using_this_clknrst == true
            continue
        end
        seq_name = get_uvc_cfg_fld(uvc_name, :class_names)["sequence"]
        push!(seq_list, "$(uvc_name)_random_$(seq_name)")
        my_str *= gen_lines_tdefs_w_param_w_seq_item_env("$(uvc_name)_random_$(seq_name)", uvc_name, "    ")
    end
    my_str = my_str[1:end-1]
    
    my_str *= """ 
    $( gen_vsqr_tdef("    ")[1:end-1] )
        // Typedefs - end 
        
        `uvm_declare_p_sequencer($(dut_name)_$(vsqr_name)_t)
        
        $(dut_name)_$(cfg_name)_t m_$(cfg_name);
        
        // Sequence instances - begin
    $( gen_long_str(seq_list, "    ", gen_line_seq_instance)[1:end-1] )
        // Sequence instances - end
        
        function new (string name="$(dut_name)_base_$(vseq_name)");
            super.new(name);
        endfunction : new
        
    """
    
    my_str *= """
        task pre_start ();
            uvm_phase phase = get_starting_phase();
            if (phase != null) begin
                phase.raise_objection(this, get_type_name());
                `uvm_info("$(uppercase(dut_name)) VSEQ", "Raising objection.", $(verbosities["raise_objection_vseq"]))
            end
            else begin
                `uvm_info("$(uppercase(dut_name)) VSEQ", "Phase is null, so could not raise objection.", $(verbosities["phase_null_vseq"]))
            end
            
            m_$(cfg_name) = p_sequencer.m_$(cfg_name);
        endtask : pre_start
        
        task post_start ();
            uvm_phase phase = get_starting_phase();
            if (phase != null) begin
                phase.drop_objection(this, get_type_name());
                `uvm_info("$(uppercase(dut_name)) VSEQ", "Dropping objection.", $(verbosities["drop_objection_vseq"]))
            end
            else begin
                `uvm_info("$(uppercase(dut_name)) VSEQ", "Phase is null, so could not drop objection.", $(verbosities["phase_null_vseq"]))
            end
        endtask : post_start
        
    """
    
    my_str *= """
        function void do_kill ();
            uvm_phase phase = get_starting_phase();
            if (phase != null) begin
                phase.drop_objection(this, get_type_name());
                `uvm_info("$(uppercase(dut_name)) VSEQ", "Sequence killed.", $(verbosities["kill_vseq"]))
            end
        endfunction : do_kill
        
    """
    
    my_str *= """
    endclass : $(dut_name)_base_$(vseq_name)
    """
    return my_str
end

gen_vseq_random() = begin
    sqr_name  = class_names["sequencer"]
    vseq_name = class_names["vsequence"]
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "env_$(class_names["config"])"
    else
        cfg_name = "$(class_names["config"])"
    end
    
    uvc_names_ = uvc_names
    if using_this_clknrst == true
        uvc_names_ = filter(x -> x!= clknrst_name, uvc_names)
    end
    
    my_str = """
    class $(dut_name)_random_$(vseq_name) $(get_vsqr_param_declaration("    "))extends $(dut_name)_base_$(vseq_name)$(gen_vsqr_param_conn("")[1:end-1]);
        
    """
    
    if env_has_params
        my_str *= """
            `uvm_object_param_utils($(dut_name)_random_$(vseq_name) $(get_vsqr_param_conn("    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_object_utils($(dut_name)_random_$(vseq_name))
        """
    end
    
    my_str *= """
        
        function new(string name="$(dut_name)_random_$(vseq_name)");
            super.new(name);
        endfunction : new
        
        task body();
            `uvm_info("$(uppercase(dut_name)) VSEQ", "Executing random sequence.", $(verbosities["executing_vseq"]))
            
    """
    
    if using_this_clknrst == true
        if get_usr_cfg_fld(:use_detailed_config_instances) == true
            clknrst_cfg_name = "agent_" * get_uvc_cfg_fld(clknrst_name, :class_names)["config"]
        else
            clknrst_cfg_name = get_uvc_cfg_fld(clknrst_name, :class_names)["config"]
        end
        seq_name = get_uvc_cfg_fld(clknrst_name, :class_names)["sequence"]
        my_str *= """
                if (m_$(cfg_name).has_$(clknrst_name)_agent) begin
                    if (m_$(cfg_name).m_$(clknrst_name)_$(clknrst_cfg_name).is_active) begin
                        m_$(clknrst_name)_reset_and_start_clk_$(seq_name) = $(clknrst_name)_reset_and_start_clk_$(seq_name)_t::type_id::create("m_$(clknrst_name)_reset_and_start_clk_$(seq_name)");
                        m_$(clknrst_name)_reset_and_start_clk_$(seq_name).set_starting_phase(get_starting_phase());
                        m_$(clknrst_name)_reset_and_start_clk_$(seq_name).start(.sequencer(p_sequencer.m_$(clknrst_name)_$(get_uvc_cfg_fld(clknrst_name, :class_names)["sequencer"])), .call_pre_post(0));
                    end
                end
                
        """
    else
        my_str *= ""
    end
    
    my_str *= """
            fork
    $( gen_long_str(uvc_names_, "            ", gen_line_rnd_seq_start)[1:end-1] )
            join
            
        endtask : body
        
    endclass : $(dut_name)_random_$(vseq_name)
    """
    return my_str
end
