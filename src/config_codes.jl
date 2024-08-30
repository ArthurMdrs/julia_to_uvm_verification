# ***********************************
# Config Codes!!!!!
# ***********************************
# No vector is necessary!!!
# ***********************************

gen_config_base(prefix_name, vec) = begin 
    name = use_short_names ? short_names_dict["config"] : "config"
    return """
    class $(prefix_name)_$(name) extends uvm_object;

        rand int some_cfg;

        `uvm_object_utils_begin($(prefix_name)_$(name))
            `uvm_field_int(some_cfg, UVM_ALL_ON)
        `uvm_object_utils_end

        function new (string name = "$(prefix_name)_$(name)");
            super.new(name);
        endfunction: new

    endclass: $(prefix_name)_$(name)
    """
    end
# ****************************************************************