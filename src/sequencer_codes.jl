# ***********************************
# Sequencer Codes!!!!!
# ***********************************
# No vector is necessary!!!
# ***********************************

gen_sequencer_base(prefix_name, vec) = begin 
    name = use_short_names ? short_names_dict["sequencer"] : "sequencer"
    cfg_name = use_short_names ? short_names_dict["config"     ] : "config"
    tr_name  = use_short_names ? short_names_dict["transaction"] : "transaction"
    return """
    class $(prefix_name)_$(name) extends uvm_sequencer#($(prefix_name)_$(tr_name));

        $(prefix_name)_$(cfg_name) cfg;

        `uvm_component_utils_begin($(prefix_name)_$(name))
            `uvm_field_object(cfg, UVM_ALL_ON)
        `uvm_component_utils_end

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            if(uvm_config_db#($(prefix_name)_$(cfg_name))::get(.cntxt(this), .inst_name(""), .field_name("cfg"), .value(cfg)))
                `uvm_info("$(uppercase(prefix_name)) SEQUENCER", "Configuration object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) SEQUENCER", "No configuration object was set!")
        endfunction: build_phase

    endclass: $(prefix_name)_$(name)
    """
    end
# ****************************************************************