# ***********************************
# Reference Model Codes
# ***********************************
# Creates a reference model to be added to the environment
# ***********************************


gen_refmod_base() = begin
    rm_name  = class_names["ref_model"]
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "env_$(class_names["config"])"
    else
        cfg_name = "$(class_names["config"])"
    end
    @assert size(uvc_names, 1) >= 1
    tr_name = get_uvc_cfg_fld(uvc_names[1], :class_names)["transaction"]
    tr_str = env_has_params ? "seq_item_t" : "$(uvc_names[1])_$(tr_name)"
    
    params_prefix = get_uvc_params_prefix(dut_name)
    
    my_str = """
    class $(dut_name)_$(rm_name) $(get_param_declaration_w_seq_item(params_prefix, "    "))extends uvm_subscriber#($(tr_str));
        
    """
    
    if env_has_params
        my_str *= """
            `uvm_component_param_utils($(dut_name)_$(rm_name) $(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(dut_name)_$(rm_name))
            
            typedef $(uvc_names[1])_$(tr_name) seq_item_t;
        """
    end
    
    my_str *= """
        
    $(gen_lines_tdefs_w_param_env(params_prefix, "$(dut_name)_$(cfg_name)", "    ")[1:end-1])
        
        $(dut_name)_$(cfg_name)_t m_$(cfg_name);
    """
    
    my_str *= """
        
        seq_item_t seq_item;
        
        uvm_analysis_port#(seq_item_t) $(rm_name)_port;
        
        function new(string name="$(dut_name)_$(rm_name)", uvm_component parent = null);
            super.new(name, parent);
            $(rm_name)_port = new("$(rm_name)_port", this);
        endfunction : new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if (m_$(cfg_name) == null)
                `uvm_fatal("$(uppercase(dut_name)) REFMOD", "No configuration object was set!")
        endfunction : build_phase
        
        function void write(seq_item_t t);
            seq_item = seq_item_t::type_id::create("seq_item");
            
            seq_item.copy(t);
            
            $(rm_name)_port.write(seq_item);
            
            `uvm_info("$(uppercase(dut_name)) REFMOD", \$sformatf("Processed item: \\n%s", seq_item.convert2string()), $(verbosities["refmod_proc_item"]))
        endfunction : write
        
    endclass : $(dut_name)_$(rm_name)
    """
    return my_str
end