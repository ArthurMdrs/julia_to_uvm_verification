class some_vip_base_sequence extends uvm_sequence#(some_vip_packet);

    `uvm_object_utils(some_vip_base_sequence)

    function new(string name="some_vip_base_sequence");
        super.new(name);
    endfunction: new

    task pre_body();
        uvm_phase phase = get_starting_phase();
        phase.raise_objection(this, get_type_name());
        `uvm_info("some_vip Sequence", "phase.raise_objection", UVM_HIGH)
    endtask: pre_body

    task post_body();
        uvm_phase phase = get_starting_phase();
        phase.drop_objection(this, get_type_name());
        `uvm_info("some_vip Sequence", "phase.drop_objection", UVM_HIGH)
    endtask: post_body

endclass: some_vip_base_sequence

//==============================================================//

class some_vip_random_seq extends some_vip_base_sequence;

    `uvm_object_utils(some_vip_random_seq)

    function new(string name="some_vip_random_seq");
        super.new(name);
    endfunction: new
    
    virtual task body();
        repeat(3) begin
            `uvm_create(req)
                void'(req.randomize());
                // It is possible to put constraints into randomize, like below.
                // void'(req.randomize() with {field_1==value_1; field_2==value_2;});
            `uvm_send(req)
        end
    endtask: body

endclass: some_vip_random_seq

//==============================================================//
