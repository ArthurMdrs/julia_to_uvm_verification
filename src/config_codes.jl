# ***********************************
# Config Codes
# ***********************************
# Creates the config class
# ***********************************

gen_config_base(prefix_name, vec) = begin 
    name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
    my_str = """
    class $(prefix_name)_$(name) $(get_param_declaration(params_vec, dut_name, "")) extends uvm_object;
        
        uvm_active_passive_enum is_active;
    """
    if agent_has_coverage
        my_str *= "    $(prefix_name)_cov_enable_enum_t cov_control;\n"
    end 
    my_str *= """
        
    """
    cov_uvm_field_str = agent_has_coverage ? "\n        `uvm_field_enum($(prefix_name)_cov_enable_enum_t, cov_control, UVM_ALL_ON)" : ""
    if has_paramaters
        my_str *= """
            `uvm_object_param_utils_begin($(prefix_name)_$(name) $(get_param_conn("    ")))
                `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)$(cov_uvm_field_str)
            `uvm_object_utils_end
            
        """
    else
        my_str *= """
            `uvm_object_utils_begin($(prefix_name)_$(name))
                `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)$(cov_uvm_field_str)
            `uvm_object_utils_end
            
        """
    end
    
    my_str *= """
        function new (string name = "$(prefix_name)_$(name)");
            super.new(name);
            is_active = UVM_ACTIVE;
    """
    if agent_has_coverage
        my_str *= "        cov_control = $(uppercase(prefix_name))_COV_DISABLE;\n"
    end 
    my_str *= """
        endfunction: new

    endclass: $(prefix_name)_$(name)
    """
    return my_str
end

gen_clknrst_config() = begin
    prefix_name = "clknrst"
    name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
    my_str = """
    class $(prefix_name)_$(name) $(get_param_declaration(params_vec, dut_name, "")) extends uvm_object;
        
        uvm_active_passive_enum is_active;
    """
    if agent_has_coverage
        my_str *= "    $(prefix_name)_cov_enable_enum_t cov_control;\n"
    end 
    my_str *= """
        
        rand $(prefix_name)_init_val_enum_t initial_rst_val;
        
    """
        
    cov_uvm_field_str = agent_has_coverage ? "\n        `uvm_field_enum($(prefix_name)_cov_enable_enum_t, cov_control, UVM_ALL_ON)" : ""
    if has_paramaters
        my_str *= """
            `uvm_object_param_utils_begin($(prefix_name)_$(name) $(get_param_conn("    ")))
                `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)$(cov_uvm_field_str)
                `uvm_field_enum($(prefix_name)_init_val_enum_t, initial_rst_val, UVM_ALL_ON)
            `uvm_object_utils_end
            
        """
    else
        my_str *= """
            `uvm_object_utils_begin($(prefix_name)_$(name))
                `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)$(cov_uvm_field_str)
                `uvm_field_enum($(prefix_name)_init_val_enum_t, initial_rst_val, UVM_ALL_ON)
            `uvm_object_utils_end
            
        """
    end
    
    my_str *= """
        function new (string name = "$(prefix_name)_$(name)");
            super.new(name);
            is_active = UVM_ACTIVE;
    """
    if agent_has_coverage
        my_str *= "        cov_control = $(uppercase(prefix_name))_COV_DISABLE;\n"
    end 
    my_str *= """
            initial_rst_val = $(uppercase(prefix_name))_INITIAL_VALUE_1;
        endfunction: new

    endclass: $(prefix_name)_$(name)
    """
    return my_str
end
    
# ****************************************************************