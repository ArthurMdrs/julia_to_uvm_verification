# *******************
# Sequence Lib Codes
# ***********************************
# Creates an example sequence library
# ***********************************

gen_base_seq(prefix_name) = begin 
    sqr_name = get_uvc_cfg_fld(prefix_name, :class_names)["sequencer"  ]
    cfg_name = get_uvc_cfg_fld(prefix_name, :class_names)["config"     ]
    tr_name  = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = get_uvc_cfg_fld(prefix_name, :uvc_has_params) ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    verb_dict = get_uvc_cfg_fld(prefix_name, :verbosities)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    gen_lines_tdefs_w_param_uvc(name, tabs) = gen_lines_tdefs_w_param(params_prefix, name, tabs)
    my_str = """
    class $(prefix_name)_base_seq $(get_param_declaration_w_seq_item(params_prefix, "    "))extends uvm_sequence #($(tr_type));
        
    """
    
    my_str *= """
    $( gen_long_str(["$(prefix_name)_$(cfg_name)"], "    ", gen_lines_tdefs_w_param_uvc)[1:end-1] )
        
        $(prefix_name)_$(cfg_name)_t $(config_inst_convention);
        
    """
    
    if get_uvc_cfg_fld(prefix_name, :uvc_has_params)
        my_str *= """
            `uvm_object_param_utils($(prefix_name)_base_seq $(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_object_utils($(prefix_name)_base_seq)
        """
    end
    
    my_str *= """
        
        `uvm_declare_p_sequencer($(prefix_name)_$(sqr_name)$(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        
        function new(string name="$(prefix_name)_base_seq");
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
            
            $(config_inst_convention) = p_sequencer.$(config_inst_convention);
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
    endclass : $(prefix_name)_base_seq
    """
    return my_str
end

gen_random_seq(prefix_name) = begin
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = get_uvc_cfg_fld(prefix_name, :uvc_has_params) ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    verb_dict = get_uvc_cfg_fld(prefix_name, :verbosities)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    my_str = """
    class $(prefix_name)_random_seq $(get_param_declaration_w_seq_item(params_prefix, "    "))extends $(prefix_name)_base_seq$(get_param_conn_w_seq_item2(params_prefix, "")[1:end-1]);
        
        `uvm_object_param_utils($(prefix_name)_random_seq$(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        
        function new(string name="$(prefix_name)_random_seq");
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
        
    endclass : $(prefix_name)_random_seq
    """
    return my_str
end

gen_clknrst_action_seq(clknrst_action, prefix_name) = begin
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = get_uvc_cfg_fld(prefix_name, :uvc_has_params) ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    verb_dict = get_uvc_cfg_fld(prefix_name, :verbosities)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    my_str = """
    class $(prefix_name)_$(clknrst_action)_seq $(get_param_declaration_w_seq_item(params_prefix, "    "))extends $(prefix_name)_base_seq$(get_param_conn_w_seq_item2(params_prefix, "")[1:end-1]);
        
        `uvm_object_param_utils($(prefix_name)_$(clknrst_action)_seq$(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        
        function new(string name="$(prefix_name)_$(clknrst_action)_seq");
            super.new(name);
        endfunction : new
        
        task body();
            `uvm_info("$(uppercase(prefix_name)) SEQ", "Executing $(clknrst_action) sequence.", $(verb_dict["executing_seq"]))
            req = $(tr_type)::type_id::create("req");
            start_item(req);
            if (!req.randomize())
                `uvm_fatal("$(prefix_name) $(clknrst_action)_seq", "Failed randomizing sequence item.")
            req.action = $(uppercase(prefix_name))_ACTION_$(uppercase(clknrst_action));
            finish_item(req);
        endtask : body
        
    endclass : $(prefix_name)_$(clknrst_action)_seq
    """
    return my_str
end

gen_clknrst_rst_and_start_clk_seq(prefix_name) = begin 
    verb_dict = get_uvc_cfg_fld(prefix_name, :verbosities)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    my_str = """
    class $(prefix_name)_reset_and_start_clk_seq $(get_param_declaration_w_seq_item(params_prefix, "    "))extends $(prefix_name)_base_seq$(get_param_conn_w_seq_item2(params_prefix, "")[1:end-1]);
        
        // Typedefs - begin
    """
    
    tdefs_list_w_seq_item = ["$(prefix_name)_start_clk_seq", "$(prefix_name)_assert_reset_seq"]
    gen_lines_tdefs_w_param_w_seq_item_uvc(name, tabs) = gen_lines_tdefs_w_param_w_seq_item2(params_prefix, name, tabs)
    my_str *= """
    $( gen_long_str(tdefs_list_w_seq_item, "    ", gen_lines_tdefs_w_param_w_seq_item_uvc)[1:end-1] )
        // Typedefs - end
        
        $(prefix_name)_start_clk_seq_t    m_start_clk_seq;
        $(prefix_name)_assert_reset_seq_t m_assert_reset_seq;
        
        `uvm_object_param_utils($(prefix_name)_reset_and_start_clk_seq$(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        
        function new(string name="$(prefix_name)_reset_and_start_clk_seq");
            super.new(name);
        endfunction : new
        
        task body();
            `uvm_info("$(uppercase(prefix_name)) SEQ", "Executing reset_and_start_clk sequence.", $(verb_dict["executing_seq"]))
            m_start_clk_seq = $(prefix_name)_start_clk_seq_t::type_id::create("m_start_clk_seq");
            m_start_clk_seq.set_starting_phase(get_starting_phase());
            m_start_clk_seq.start(.sequencer(p_sequencer));
            
            m_assert_reset_seq = $(prefix_name)_assert_reset_seq_t::type_id::create("m_assert_reset_seq");
            m_assert_reset_seq.set_starting_phase(get_starting_phase());
            m_assert_reset_seq.start(.sequencer(p_sequencer));
        endtask : body
        
    endclass : $(prefix_name)_reset_and_start_clk_seq
    """
    return my_str
end

# ****************************************************************
