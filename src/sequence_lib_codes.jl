# *******************
# Sequence Lib Codes
# ***********************************
# Creates an example sequence library
# ***********************************

gen_base_seq(prefix_name) = begin 
    sqr_name = get_uvc_cfg_fld(prefix_name, :class_names)["sequencer" ]
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "agent_" * get_uvc_cfg_fld(prefix_name, :class_names)["config"]
    else
        cfg_name = get_uvc_cfg_fld(prefix_name, :class_names)["config"]
    end
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = get_uvc_cfg_fld(prefix_name, :uvc_has_params) ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    seq_name = get_uvc_cfg_fld(prefix_name, :class_names)["sequence"  ]
    verb_dict = get_uvc_cfg_fld(prefix_name, :verbosities)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    gen_lines_tdefs_w_param_uvc(name, tabs) = gen_lines_tdefs_w_param(params_prefix, name, tabs)
    my_str = """
    class $(prefix_name)_base_$(seq_name) $(get_param_declaration_w_seq_item(params_prefix, "    "))extends uvm_sequence #($(tr_type));
        
    """
    
    my_str *= """
    $( gen_long_str(["$(prefix_name)_$(cfg_name)"], "    ", gen_lines_tdefs_w_param_uvc)[1:end-1] )
        
        $(prefix_name)_$(cfg_name)_t m_$(cfg_name);
        
    """
    
    if get_uvc_cfg_fld(prefix_name, :uvc_has_params)
        my_str *= """
            `uvm_object_param_utils($(prefix_name)_base_$(seq_name) $(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_object_utils($(prefix_name)_base_$(seq_name))
        """
    end
    
    my_str *= """
        
        `uvm_declare_p_sequencer($(prefix_name)_$(sqr_name)$(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        
        function new(string name="$(prefix_name)_base_$(seq_name)");
            super.new(name);
        endfunction : new
        
    """
    
    my_str *= """
        task pre_start();
            uvm_phase phase = get_starting_phase();
            if (phase != null) begin
                phase.raise_objection(this, get_type_name());
                `uvm_info("$(uppercase(prefix_name)) SEQ", "Raising objection.", $(verb_dict["raise_objection_seq"]))
            end
            else begin
                `uvm_info("$(uppercase(prefix_name)) SEQ", "Phase is null, so could not raise objection.", $(verb_dict["phase_null_seq"]))
            end
            
            m_$(cfg_name) = p_sequencer.m_$(cfg_name);
        endtask : pre_start
        
        task post_start();
            uvm_phase phase = get_starting_phase();
            if (phase != null) begin
                phase.drop_objection(this, get_type_name());
                `uvm_info("$(uppercase(prefix_name)) SEQ", "Dropping objection.", $(verb_dict["drop_objection_seq"]))
            end
            else begin
                `uvm_info("$(uppercase(prefix_name)) SEQ", "Phase is null, so could not drop objection.", $(verb_dict["phase_null_seq"]))
            end
        endtask : post_start
        
    """
    
    my_str *= """
        function void do_kill ();
            uvm_phase phase = get_starting_phase();
            if (phase != null) begin
                phase.drop_objection(this, get_type_name());
                `uvm_info("$(uppercase(prefix_name)) SEQ", "Sequence killed.", $(verbosities["kill_seq"]))
            end
        endfunction : do_kill
        
    """
    
        my_str *= """
    endclass : $(prefix_name)_base_$(seq_name)
    """
    return my_str
end

gen_random_seq(prefix_name) = begin
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = get_uvc_cfg_fld(prefix_name, :uvc_has_params) ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    seq_name = get_uvc_cfg_fld(prefix_name, :class_names)["sequence"  ]
    verb_dict = get_uvc_cfg_fld(prefix_name, :verbosities)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    my_str = """
    class $(prefix_name)_random_$(seq_name) $(get_param_declaration_w_seq_item(params_prefix, "    "))extends $(prefix_name)_base_$(seq_name)$(get_param_conn_w_seq_item2(params_prefix, "")[1:end-1]);
        
        `uvm_object_param_utils($(prefix_name)_random_$(seq_name)$(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        
        function new(string name="$(prefix_name)_random_$(seq_name)");
            super.new(name);
        endfunction : new
        
        task body();
            `uvm_info("$(uppercase(prefix_name)) SEQ", "Executing random sequence.", $(verb_dict["executing_seq"]))
            req = $(tr_type)::type_id::create("req");
            repeat(3) begin
                start_item(req);
                if (!req.randomize())
                    `uvm_fatal("$(uppercase(prefix_name)) SEQ", "Could not randomize transaction.")
                // It is possible to put constraints into randomize, like below.
                // if (!(req.randomize() with {field_1==value_1; field_2==value_2;}));
                finish_item(req);
            end
        endtask : body
        
    endclass : $(prefix_name)_random_$(seq_name)
    """
    return my_str
end

gen_clknrst_action_seq(clknrst_action, prefix_name) = begin
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = get_uvc_cfg_fld(prefix_name, :uvc_has_params) ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    seq_name = get_uvc_cfg_fld(prefix_name, :class_names)["sequence"  ]
    verb_dict = get_uvc_cfg_fld(prefix_name, :verbosities)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    my_str = """
    class $(prefix_name)_$(clknrst_action)_$(seq_name) $(get_param_declaration_w_seq_item(params_prefix, "    "))extends $(prefix_name)_base_$(seq_name)$(get_param_conn_w_seq_item2(params_prefix, "")[1:end-1]);
        
        `uvm_object_param_utils($(prefix_name)_$(clknrst_action)_$(seq_name)$(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        
        function new(string name="$(prefix_name)_$(clknrst_action)_$(seq_name)");
            super.new(name);
        endfunction : new
        
        task body();
            `uvm_info("$(uppercase(prefix_name)) SEQ", "Executing $(clknrst_action) sequence.", $(verb_dict["executing_seq"]))
            req = $(tr_type)::type_id::create("req");
            start_item(req);
            if (!req.randomize())
                `uvm_fatal("$(prefix_name) $(clknrst_action)_$(seq_name)", "Failed randomizing sequence item.")
            req.action = $(uppercase(prefix_name))_ACTION_$(uppercase(clknrst_action));
            finish_item(req);
        endtask : body
        
    endclass : $(prefix_name)_$(clknrst_action)_$(seq_name)
    """
    return my_str
end

gen_clknrst_rst_and_start_clk_seq(prefix_name) = begin 
    seq_name = get_uvc_cfg_fld(prefix_name, :class_names)["sequence"]
    verb_dict = get_uvc_cfg_fld(prefix_name, :verbosities)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    my_str = """
    class $(prefix_name)_reset_and_start_clk_$(seq_name) $(get_param_declaration_w_seq_item(params_prefix, "    "))extends $(prefix_name)_base_$(seq_name)$(get_param_conn_w_seq_item2(params_prefix, "")[1:end-1]);
        
        // Typedefs - begin
    """
    
    tdefs_list_w_seq_item = ["$(prefix_name)_start_clk_$(seq_name)", "$(prefix_name)_assert_reset_$(seq_name)"]
    gen_lines_tdefs_w_param_w_seq_item_uvc(name, tabs) = gen_lines_tdefs_w_param_w_seq_item2(params_prefix, name, tabs)
    my_str *= """
    $( gen_long_str(tdefs_list_w_seq_item, "    ", gen_lines_tdefs_w_param_w_seq_item_uvc)[1:end-1] )
        // Typedefs - end
        
        $(prefix_name)_start_clk_$(seq_name)_t    m_start_clk_$(seq_name);
        $(prefix_name)_assert_reset_$(seq_name)_t m_assert_reset_$(seq_name);
        
        `uvm_object_param_utils($(prefix_name)_reset_and_start_clk_$(seq_name)$(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        
        function new(string name="$(prefix_name)_reset_and_start_clk_$(seq_name)");
            super.new(name);
        endfunction : new
        
        task body();
            `uvm_info("$(uppercase(prefix_name)) SEQ", "Executing reset_and_start_clk sequence.", $(verb_dict["executing_seq"]))
            m_start_clk_$(seq_name) = $(prefix_name)_start_clk_$(seq_name)_t::type_id::create("m_start_clk_$(seq_name)");
            m_start_clk_$(seq_name).set_starting_phase(get_starting_phase());
            m_start_clk_$(seq_name).start(.sequencer(p_sequencer));
            
            m_assert_reset_$(seq_name) = $(prefix_name)_assert_reset_$(seq_name)_t::type_id::create("m_assert_reset_$(seq_name)");
            m_assert_reset_$(seq_name).set_starting_phase(get_starting_phase());
            m_assert_reset_$(seq_name).start(.sequencer(p_sequencer));
        endtask : body
        
    endclass : $(prefix_name)_reset_and_start_clk_$(seq_name)
    """
    return my_str
end

# ****************************************************************
