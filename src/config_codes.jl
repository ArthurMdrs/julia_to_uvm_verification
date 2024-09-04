# ***********************************
# Config Codes!!!!!
# ***********************************
# No vector is necessary!!!
# ***********************************

gen_config_base(prefix_name, vec) = begin 
    name = use_short_names ? short_names_dict["config"] : "config"
    return """
    class $(prefix_name)_$(name) extends uvm_object;

        uvm_active_passive_enum is_active;
        $(prefix_name)_cov_enable_enum cov_control;

        `uvm_object_utils_begin($(prefix_name)_$(name))
            `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
            `uvm_field_enum($(prefix_name)_cov_enable_enum, cov_control, UVM_ALL_ON)
        `uvm_object_utils_end

        function new (string name = "$(prefix_name)_$(name)");
            super.new(name);
            is_active = UVM_ACTIVE;
            cov_control = $(uppercase(prefix_name))_COV_ENABLE;
        endfunction: new

    endclass: $(prefix_name)_$(name)
    """
end

gen_clknrst_config() = begin
    prefix_name = "clknrst"
    name = use_short_names ? short_names_dict["config"] : "config"
    return """
    class $(prefix_name)_$(name) extends uvm_object;

        uvm_active_passive_enum is_active;
        $(prefix_name)_cov_enable_enum cov_control;
        
        rand $(prefix_name)_init_val_enum initial_rst_val;

        `uvm_object_utils_begin($(prefix_name)_$(name))
            `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
            `uvm_field_enum($(prefix_name)_cov_enable_enum, cov_control, UVM_ALL_ON)
            `uvm_field_enum($(prefix_name)_init_val_enum, initial_rst_val, UVM_ALL_ON)
        `uvm_object_utils_end

        function new (string name = "$(prefix_name)_$(name)");
            super.new(name);
            is_active = UVM_ACTIVE;
            cov_control = $(uppercase(prefix_name))_COV_ENABLE;
            initial_rst_val = $(uppercase(prefix_name))_INITIAL_VALUE_1;
        endfunction: new

    endclass: $(prefix_name)_$(name)
    """
end
    
# ****************************************************************