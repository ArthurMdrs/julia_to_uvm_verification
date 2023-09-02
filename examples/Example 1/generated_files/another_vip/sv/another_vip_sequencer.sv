class another_vip_sequencer extends uvm_sequencer#(another_vip_packet);

    `uvm_component_utils(another_vip_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

endclass: another_vip_sequencer
