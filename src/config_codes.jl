# ***********************************
# Config Codes
# ***********************************
# Creates the config class
# ***********************************

gen_config_base(prefix_name, vec) = begin 
    cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
    my_str = """
    class $(prefix_name)_$(cfg_name) $(get_param_declaration(params_vec, dut_name, "")) extends uvm_object;
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_object_param_utils($(prefix_name)_$(cfg_name) $(get_param_conn("    ")))
            
        """
    else
        my_str *= """
            `uvm_object_utils($(prefix_name)_$(cfg_name))
            
        """
    end
    
    if agent_has_coverage
        my_str *= "    bit has_coverage;\n"
    end 
    
    my_str *= """
        bit has_monitor;
        uvm_active_passive_enum is_active;
        
        function new (string name = "$(prefix_name)_$(cfg_name)");
            super.new(name);
            is_active = UVM_ACTIVE;
    """
    if agent_has_coverage
        my_str *= "        has_coverage = 1'b1;\n"
    end 
    my_str *= """
            has_monitor = 1'b1;
        endfunction: new

    endclass: $(prefix_name)_$(cfg_name)
    """
    return my_str
end

gen_clknrst_config() = begin
    prefix_name = "clknrst"
    cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
    my_str = """
    class $(prefix_name)_$(cfg_name) $(get_param_declaration(params_vec, dut_name, "")) extends uvm_object;
        
    """
        
    if has_paramaters
        my_str *= """
            `uvm_object_param_utils($(prefix_name)_$(cfg_name) $(get_param_conn("    ")))
            
        """
    else
        my_str *= """
            `uvm_object_utils($(prefix_name)_$(cfg_name))
            
        """
    end
    
    if agent_has_coverage
        my_str *= "    bit has_coverage;\n"
    end 
    
    my_str *= """
        bit has_monitor;
        uvm_active_passive_enum is_active;
        
        rand $(prefix_name)_init_val_enum_t initial_rst_val;
        
        bit set_clk_period_from_config;
        int unsigned clk_period; // In ps
        
        function new (string name = "$(prefix_name)_$(cfg_name)");
            super.new(name);
            is_active = UVM_ACTIVE;
    """
    if agent_has_coverage
        my_str *= "        has_coverage = 1'b0;\n"
    end 
    my_str *= """
            has_monitor = 1'b0;
            initial_rst_val = $(uppercase(prefix_name))_INITIAL_VALUE_1;
            
            set_clk_period_from_config = 1'b0;
            clk_period = 10_000; // 10ns
        endfunction: new

    endclass: $(prefix_name)_$(cfg_name)
    """
    return my_str
end
    
# ****************************************************************