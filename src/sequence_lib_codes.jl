# *******************
# Sequence Lib Codes!!!!!
# ***********************************
# No vector is necessary!!!
# ***********************************

gen_base_seq(prefix_name) = begin 
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
    """
end

gen_sequence_lib_base(prefix_name, vec) = begin 
    my_str = gen_base_seq(prefix_name)
    my_str *= """

    //==============================================================//

    class $(prefix_name)_random_seq extends $(prefix_name)_base_sequence;

        `uvm_object_utils($(prefix_name)_random_seq)

        function new(string name="$(prefix_name)_random_seq");
            super.new(name);
        endfunction: new
        
        virtual task body();
            `uvm_info("$(prefix_name) Sequence", "Executing random sequence.", UVM_LOW)
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
    return my_str
end

gen_clknrst_seq_lines(clknrst_action, prefix_name) = begin
    my_str = """

    //==============================================================//

    class $(prefix_name)_$(clknrst_action)_seq extends $(prefix_name)_base_sequence;

        `uvm_object_utils($(prefix_name)_$(clknrst_action)_seq)

        function new(string name="$(prefix_name)_$(clknrst_action)_seq");
            super.new(name);
        endfunction: new
        
        virtual task body();
            `uvm_info("$(prefix_name) Sequence", "Executing $(clknrst_action) sequence.", UVM_LOW)
            `uvm_create(req)
            if (!req.randomize())
                `uvm_fatal("$(prefix_name) $(clknrst_action)_seq", "Failed randomizing sequence item.")
            req.action = $(uppercase(prefix_name))_ACTION_$(uppercase(clknrst_action));
            `uvm_send(req)
        endtask: body

    endclass: $(prefix_name)_$(clknrst_action)_seq
    """
    return my_str
end

gen_clknrst_sequence_lib() = begin 
    prefix_name = "clknrst"
    actions_vec = ["start_clk", "stop_clk", "restart_clk", "assert_reset"]
    my_str = gen_base_seq("clknrst")
    my_str *= gen_long_str(actions_vec, prefix_name, gen_clknrst_seq_lines)
    my_str *= """

    //==============================================================//

    class $(prefix_name)_reset_and_start_clk_seq extends $(prefix_name)_base_sequence;
        
        $(prefix_name)_start_clk_seq    start_clk_seq;
        $(prefix_name)_assert_reset_seq assert_reset_seq;
        
        `uvm_object_utils($(prefix_name)_reset_and_start_clk_seq)

        function new(string name="$(prefix_name)_reset_and_start_clk_seq");
            super.new(name);
        endfunction: new
        
        virtual task body();
            `uvm_info("$(prefix_name) Sequence", "Executing reset_and_start_clk sequence.", UVM_LOW)
            `uvm_do(start_clk_seq)
            // p_sequencer.vif.wait_clk_posedge();
            p_sequencer.vif.wait_clk_negedge();
            `uvm_do(assert_reset_seq)
        endtask: body

    endclass: $(prefix_name)_reset_and_start_clk_seq

    //==============================================================//
    """
    return my_str
end

# ****************************************************************
