# *******************
# Sequence Lib Codes
# ***********************************
# Creates an example sequence library
# ***********************************

gen_base_seq(prefix_name) = begin 
    sqr_name = use_short_names ? short_names_dict["sequencer"  ] : long_names_dict["sequencer"  ]
    cfg_name = use_short_names ? short_names_dict["config"     ] : long_names_dict["config"     ]
    tr_name  = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
    tr_type = has_paramaters ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    my_str = """
    class $(prefix_name)_base_sequence $(get_param_declaration_w_seq_item(params_vec, dut_name, "    "))extends uvm_sequence #($(tr_type));
        
    """
    
    my_str *= """
    $( gen_long_str(["$(prefix_name)_$(cfg_name)"], "    ", gen_lines_tdefs_w_param)[1:end-1] )
        
        $(prefix_name)_$(cfg_name)_t $(config_inst_convention);
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_object_param_utils($(prefix_name)_base_sequence $(get_param_conn_w_seq_item2("    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_object_utils($(prefix_name)_base_sequence)
        """
    end
    
    my_str *= """
        
        `uvm_declare_p_sequencer($(prefix_name)_$(sqr_name)$(get_param_conn_w_seq_item2("    ")[1:end-1]))

        function new(string name="$(prefix_name)_base_sequence");
            super.new(name);
        endfunction: new
        
    """
    
    my_str *= """
        task pre_start();
            uvm_phase phase = get_starting_phase();
            if (phase != null) begin
                phase.raise_objection(this, get_type_name());
                `uvm_info("$(uppercase(prefix_name)) SEQ", "Raising objection.", UVM_HIGH)
            end
            else begin
                `uvm_info("$(uppercase(prefix_name)) SEQ", "Phase is null, so could not raise objection.", UVM_LOW)
            end
        
            $(config_inst_convention) = p_sequencer.$(config_inst_convention);
        endtask: pre_start
        
        task post_start();
            uvm_phase phase = get_starting_phase();
            if (phase != null) begin
                phase.drop_objection(this, get_type_name());
                `uvm_info("$(uppercase(prefix_name)) SEQ", "Dropping objection.", UVM_HIGH)
            end
            else begin
                `uvm_info("$(uppercase(prefix_name)) SEQ", "Phase is null, so could not drop objection.", UVM_LOW)
            end
        endtask: post_start
        
    """
    
    # my_str *= """
    #     task pre_body();
    #         uvm_phase phase = get_starting_phase();
    #         phase.raise_objection(this, get_type_name());
    #         `uvm_info("$(prefix_name) Sequence", "phase.raise_objection", UVM_HIGH)
    #     endtask: pre_body
        
    #     task post_body();
    #         uvm_phase phase = get_starting_phase();
    #         phase.drop_objection(this, get_type_name());
    #         `uvm_info("$(prefix_name) Sequence", "phase.drop_objection", UVM_HIGH)
    #     endtask: post_body
        
    # """
    
        my_str *= """
    endclass: $(prefix_name)_base_sequence
    """
    return my_str
end

gen_sequence_lib_base(prefix_name, vec) = begin 
    tr_name  = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
    tr_type = has_paramaters ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    my_str = gen_base_seq(prefix_name)
    my_str *= """

    //==============================================================//

    class $(prefix_name)_random_seq $(get_param_declaration_w_seq_item(params_vec, dut_name, "    "))extends $(prefix_name)_base_sequence$(get_param_conn_w_seq_item2("")[1:end-1]);
        
        `uvm_object_param_utils($(prefix_name)_random_seq$(get_param_conn_w_seq_item2("    ")[1:end-1]))
        
        function new(string name="$(prefix_name)_random_seq");
            super.new(name);
        endfunction: new
        
        task body();
            `uvm_info("$(uppercase(prefix_name)) SEQ", "Executing random sequence.", UVM_LOW)
            req = $(tr_type)::type_id::create("req");
            repeat(3) begin
                start_item(req);
                    void'(req.randomize());
                    // It is possible to put constraints into randomize, like below.
                    // void'(req.randomize() with {field_1==value_1; field_2==value_2;});
                finish_item(req);
            end
        endtask: body
        
    endclass: $(prefix_name)_random_seq

    //==============================================================//
    """
    return my_str
end

gen_clknrst_seq_lines(clknrst_action, prefix_name) = begin
    tr_name  = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
    tr_type = has_paramaters ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    my_str = """

    //==============================================================//

    class $(prefix_name)_$(clknrst_action)_seq $(get_param_declaration_w_seq_item(params_vec, dut_name, "    "))extends $(prefix_name)_base_sequence$(get_param_conn_w_seq_item2("")[1:end-1]);

        `uvm_object_param_utils($(prefix_name)_$(clknrst_action)_seq$(get_param_conn_w_seq_item2("    ")[1:end-1]))

        function new(string name="$(prefix_name)_$(clknrst_action)_seq");
            super.new(name);
        endfunction: new
        
        task body();
            `uvm_info("$(uppercase(prefix_name)) SEQ", "Executing $(clknrst_action) sequence.", UVM_LOW)
            req = $(tr_type)::type_id::create("req");
            start_item(req);
            if (!req.randomize())
                `uvm_fatal("$(prefix_name) $(clknrst_action)_seq", "Failed randomizing sequence item.")
            req.action = $(uppercase(prefix_name))_ACTION_$(uppercase(clknrst_action));
            finish_item(req);
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

    class $(prefix_name)_reset_and_start_clk_seq $(get_param_declaration_w_seq_item(params_vec, dut_name, "    "))extends $(prefix_name)_base_sequence$(get_param_conn_w_seq_item2("")[1:end-1]);
        
        // Typedefs - begin
    """
    
    tdefs_list_w_seq_item = ["$(prefix_name)_start_clk_seq", "$(prefix_name)_assert_reset_seq"]
    my_str *= """
    $( gen_long_str(tdefs_list_w_seq_item, "    ", gen_lines_tdefs_w_param_w_seq_item2)[1:end-1] )
        // Typedefs - end
        
        $(prefix_name)_start_clk_seq_t    m_start_clk_seq;
        $(prefix_name)_assert_reset_seq_t m_assert_reset_seq;
        
        `uvm_object_param_utils($(prefix_name)_reset_and_start_clk_seq$(get_param_conn_w_seq_item2("    ")[1:end-1]))

        function new(string name="$(prefix_name)_reset_and_start_clk_seq");
            super.new(name);
        endfunction: new
        
        task body();
            `uvm_info("$(uppercase(prefix_name)) SEQ", "Executing reset_and_start_clk sequence.", UVM_LOW)
            m_start_clk_seq = $(prefix_name)_start_clk_seq_t::type_id::create("m_start_clk_seq");
            m_start_clk_seq.set_starting_phase(get_starting_phase());
            m_start_clk_seq.start(.sequencer(p_sequencer));
            
            m_assert_reset_seq = $(prefix_name)_assert_reset_seq_t::type_id::create("m_assert_reset_seq");
            m_assert_reset_seq.set_starting_phase(get_starting_phase());
            m_assert_reset_seq.start(.sequencer(p_sequencer), .call_pre_post(0));
        endtask: body

    endclass: $(prefix_name)_reset_and_start_clk_seq

    //==============================================================//
    """
    return my_str
end

# ****************************************************************
