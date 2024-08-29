# ***********************************
# Sequencer Codes!!!!!
# ***********************************
# No vector is necessary!!!
# ***********************************

gen_sequencer_base(prefix_name, vec) = begin 
    name = use_short_names ? short_names_dict["sequencer"] : "sequencer"
    tr_name = use_short_names ? short_names_dict["transaction"] : "transaction"
    return """
    class $(prefix_name)_$(name) extends uvm_sequencer#($(prefix_name)_$(tr_name));

        `uvm_component_utils($(prefix_name)_$(name))

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction: new

    endclass: $(prefix_name)_$(name)
    """
    end
# ****************************************************************