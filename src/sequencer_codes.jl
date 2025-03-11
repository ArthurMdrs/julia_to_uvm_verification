# ***********************************
# Sequencer Codes
# ***********************************
# Creates the sequencer class
# ***********************************

gen_sequencer_base(prefix_name) = begin 
    sqr_name = get_uvc_cfg_fld(prefix_name, :class_names)["sequencer"]
    cfg_name = get_uvc_cfg_fld(prefix_name, :class_names)["config"]
    tr_name  = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = has_paramaters ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    my_str = """
    class $(prefix_name)_$(sqr_name) $(get_param_declaration_w_seq_item(params_vec, dut_name, "    "))extends uvm_sequencer#($(tr_type));
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_component_param_utils($(prefix_name)_$(sqr_name) $(get_param_conn_w_seq_item2(dut_name, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(prefix_name)_$(sqr_name))
        """
    end
    
    my_str *= """
        
    $( gen_lines_tdefs_w_param("$(prefix_name)_$(cfg_name)", "    ")[1:end-1] )
    $( gen_line_vif_typedef(prefix_name, "    ")[1:end-1] )
        
        $(prefix_name)_$(cfg_name)_t $(config_inst_convention);
        
        $(prefix_name)_vif_t vif;
        
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction : new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if(uvm_config_db#($(prefix_name)_$(cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("$(config_inst_convention)"), .value($(config_inst_convention))))
                `uvm_info("$(uppercase(prefix_name)) SEQUENCER", "Configuration object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) SEQUENCER", "No configuration object was set!")
            
            if(uvm_config_db#($(prefix_name)_vif_t)::get(.cntxt(this), .inst_name(""), .field_name("vif"), .value(vif)))
                `uvm_info("$(uppercase(prefix_name)) SEQUENCER", "Virtual interface was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) SEQUENCER", "No interface was set!")
        endfunction : build_phase
        
    endclass : $(prefix_name)_$(sqr_name)
    """
    return my_str
end

gen_clknrst_sequencer(prefix_name) = gen_sequencer_base(prefix_name)

# ****************************************************************