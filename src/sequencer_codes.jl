# ***********************************
# Sequencer Codes
# ***********************************
# Creates the sequencer class
# ***********************************

gen_sequencer_base(prefix_name) = begin 
    sqr_name = get_uvc_cfg_fld(prefix_name, :class_names)["sequencer"  ]
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "agent_" * get_uvc_cfg_fld(prefix_name, :class_names)["config"]
    else
        cfg_name = get_uvc_cfg_fld(prefix_name, :class_names)["config" ]
    end
    tr_name  = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = get_uvc_cfg_fld(prefix_name, :uvc_has_params) ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    gen_lines_tdefs_w_param_uvc(name, tabs) = gen_lines_tdefs_w_param(params_prefix, name, tabs)
    my_str = """
    class $(prefix_name)_$(sqr_name) $(get_param_declaration_w_seq_item(params_prefix, "    "))extends uvm_sequencer#($(tr_type));
        
    """
    
    if get_uvc_cfg_fld(prefix_name, :uvc_has_params)
        my_str *= """
            `uvm_component_param_utils($(prefix_name)_$(sqr_name) $(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(prefix_name)_$(sqr_name))
        """
    end
    
    my_str *= """
        
    $( gen_lines_tdefs_w_param_uvc("$(prefix_name)_$(cfg_name)", "    ")[1:end-1] )
    $( gen_line_vif_typedef(prefix_name, "    ")[1:end-1] )
        
        $(prefix_name)_$(cfg_name)_t m_$(cfg_name);
        
        $(prefix_name)_vif_t vif;
        
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction : new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if (m_$(cfg_name) == null)
                `uvm_fatal("$(uppercase(prefix_name)) SEQUENCER", "No configuration object was set!")
    """
    if get_uvc_cfg_fld(prefix_name, :vif_in_config) == false
        my_str *= """
                
        $( gen_vif_config_db_component(prefix_name, "        ", "SEQUENCER")[1:end-1] )
        """
    else
        my_str *= """
                
                if (m_$(cfg_name).vif == null)
                    `uvm_fatal("$(uppercase(prefix_name)) SEQUENCER", "No interface was set!")
                vif = m_$(cfg_name).vif;
        """
    end
    my_str *= """
        endfunction : build_phase
        
    endclass : $(prefix_name)_$(sqr_name)
    """
    return my_str
end

gen_clknrst_sequencer(prefix_name) = gen_sequencer_base(prefix_name)

# ****************************************************************