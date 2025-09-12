# ***********************************
# Config Codes
# ***********************************
# Creates the config class
# ***********************************

gen_config(prefix_name, type::uvc_class_type) = begin 
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "agent_" * get_uvc_cfg_fld(prefix_name, :class_names)["config"]
    else
        cfg_name = get_uvc_cfg_fld(prefix_name, :class_names)["config"]
    end
    agent_has_coverage = get_uvc_cfg_fld(prefix_name, :agent_has_coverage)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    my_str = """
    class $(prefix_name)_$(cfg_name) $(get_param_declaration(params_prefix, "    ")) extends uvm_object;
        
    """
    
    if get_uvc_cfg_fld(prefix_name, :uvc_has_params)
        my_str *= """
            `uvm_object_param_utils($(prefix_name)_$(cfg_name) $(get_param_conn(params_prefix, "    ")))
            
        """
    else
        my_str *= """
            `uvm_object_utils($(prefix_name)_$(cfg_name))
            
        """
    end
    
    if get_uvc_cfg_fld(prefix_name, :vif_in_config) == true
        my_str *= """
        $( gen_line_vif_typedef(prefix_name, "    ")[1:end-1] )
                
            $(prefix_name)_vif_t vif;
        """
    end
    
    if agent_has_coverage
        my_str *= "    bit has_coverage;\n"
    end 
    
    my_str *= """
        bit has_monitor;
        uvm_active_passive_enum is_active;
        
    """
    
    if type == clknrst::uvc_class_type
        my_str *= """
            rand $(prefix_name)_init_val_enum_t initial_rst_val;
            
            bit set_clk_period_from_config;
            int unsigned clk_period; // In ps
            
        """
    end
    
    my_str *= """
        function new (string name = "$(prefix_name)_$(cfg_name)");
            super.new(name);
    """
    if agent_has_coverage
        my_str *= "        has_coverage = 1'b1;\n"
    end 
    my_str *= """
            has_monitor = 1'b1;
            is_active = UVM_ACTIVE;
    """
    
    if type == clknrst::uvc_class_type
        my_str *= """
                initial_rst_val = $(uppercase(prefix_name))_INITIAL_VALUE_1;
                set_clk_period_from_config = 1'b0;
                clk_period = 10_000; // 10ns
        """
    end
    
    my_str *= """
        endfunction : new
        
    endclass : $(prefix_name)_$(cfg_name)
    """
    return my_str
end

gen_config_base(prefix_name) = gen_config(prefix_name, normal::uvc_class_type)
gen_clknrst_config(prefix_name) = gen_config(prefix_name, clknrst::uvc_class_type)

# ****************************************************************