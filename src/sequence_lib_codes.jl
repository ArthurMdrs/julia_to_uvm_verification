# *******************
# Sequence Lib Codes!!!!!
# ***********************************
# No vector is necessary!!!
# ***********************************

gen_sequence_lib_base(prefix_name, vec) = begin 
    cfg_name = use_short_names ? short_names_dict["config"     ] : "config"
    sqr_name = use_short_names ? short_names_dict["sequencer"  ] : "sequencer"
    tr_name  = use_short_names ? short_names_dict["transaction"] : "transaction"
    return """
    class $(prefix_name)_base_sequence extends uvm_sequence#($(prefix_name)_$(tr_name));

        $(prefix_name)_$(cfg_name) cfg;

        `uvm_object_utils($(prefix_name)_base_sequence)
        `uvm_declare_p_sequencer($(prefix_name)_$(sqr_name))

        function new(string name="$(prefix_name)_base_sequence");
            super.new(name);
        endfunction: new

        task pre_start();
            cfg = p_sequencer.cfg;
        endtask: pre_start

        task pre_body();
            uvm_phase phase = get_starting_phase();
            phase.raise_objection(this, get_type_name());
            `uvm_info("$(prefix_name) Sequence", "phase.raise_objection", UVM_HIGH)
        endtask: pre_body

        task post_body();
            uvm_phase phase = get_starting_phase();
            phase.drop_objection(this, get_type_name());
            `uvm_info("$(prefix_name) Sequence", "phase.drop_objection", UVM_HIGH)
        endtask: post_body

    endclass: $(prefix_name)_base_sequence

    //==============================================================//

    class $(prefix_name)_random_seq extends $(prefix_name)_base_sequence;

        `uvm_object_utils($(prefix_name)_random_seq)

        function new(string name="$(prefix_name)_random_seq");
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

    endclass: $(prefix_name)_random_seq

    //==============================================================//
    """
end
# ****************************************************************
