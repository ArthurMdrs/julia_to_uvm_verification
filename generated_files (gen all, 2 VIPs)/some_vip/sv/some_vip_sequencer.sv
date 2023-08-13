class some_vip_sequencer extends uvm_sequencer#(some_vip_packet);

    `uvm_component_utils(some_vip_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

endclass: some_vip_sequencer
