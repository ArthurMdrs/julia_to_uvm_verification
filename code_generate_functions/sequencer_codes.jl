# ***********************************
# Sequencer Codes!!!!!
# ***********************************
# No vector is necessary!!!
# ***********************************

gen_sequencer_base(prefix_name, vec) = """
    class $(prefix_name)_sequencer extends uvm_sequencer#($(prefix_name)_packet);

        `uvm_component_utils($(prefix_name)_sequencer)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction: new

    endclass: $(prefix_name)_sequencer
    """
# ****************************************************************