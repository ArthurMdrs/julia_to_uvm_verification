# ***********************************
# Tests Codes
# ***********************************
# Creates an example test library
# ***********************************

# gen_line_sequences_config(uvc_name, tabs) = begin
#     return "$(tabs)uvm_config_wrapper::set(this, \"env.agent_$(uvc_name).sequencer.run_phase\", \"default_sequence\", $(uvc_name)_random_seq::get_type());\n"
# end
gen_vif_config_db_tests(uvc_name, tabs) = begin
    my_str = """
    $(tabs)if(uvm_config_db#($(uvc_name)_vif_t)::get(.cntxt(this), .inst_name(""), .field_name("$(uvc_name)_vif"), .value($(uvc_name)_vif)))
    $(tabs)    `uvm_info("$(uppercase(dut_name)) BASE TEST", "$(uppercase(uvc_name)) virtual interface was successfully set!", UVM_MEDIUM)
    $(tabs)else
    $(tabs)    `uvm_fatal("$(uppercase(dut_name)) BASE TEST", "No $(uppercase(uvc_name)) interface was set!")
    """
    if get_uvc_cfg_fld(uvc_name, :vif_in_config) == false
        my_str *= """
        $(tabs)uvm_config_db#($(uvc_name)_vif_t)::set(.cntxt(this), .inst_name("m_$(dut_name)_env"), .field_name("$(uvc_name)_vif"), .value($(uvc_name)_vif));
        """
    end
    my_str *= """
    $(tabs)
    """
    return my_str
end
gen_line_cfg_create(uvc_name, tabs) = begin
    cfg_name = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    my_str = """
    $(tabs)m_$(uvc_name)_$(cfg_name) = $(uvc_name)_$(cfg_name)_t::type_id::create("m_$(uvc_name)_$(cfg_name)");
    """
    return my_str
end
gen_line_cfg_set(uvc_name, tabs) = begin
    cfg_name = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    my_str = """
    $(tabs)uvm_config_db#($(uvc_name)_$(cfg_name)_t)::set(.cntxt(this), .inst_name("m_$(dut_name)_env"), .field_name("m_$(uvc_name)_$(cfg_name)"), .value(m_$(uvc_name)_$(cfg_name)));
    """
    return my_str
end
gen_vseq_tdef(vseq_name, tabs) = begin
    vsqr_name  = class_names["vsequencer"]
    my_str = """
    $(tabs)typedef $(dut_name)_$(vseq_name) $(gen_vsqr_param_conn(tabs))$(dut_name)_$(vseq_name)_t;
    """
    return my_str
end
gen_line_assign_vif_to_config(uvc_name, tabs) = begin
    cfg_name = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    if get_uvc_cfg_fld(uvc_name, :vif_in_config) == true
        my_str = """
        $(tabs)m_$(uvc_name)_$(cfg_name).vif = $(uvc_name)_vif;
        """
    else
        my_str = ""
    end
    return my_str
end
gen_line_assign_config_test(uvc_name, tabs) = begin
    cfg_name = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    env_cfg_name = class_names["config"]
    my_str = "$(tabs)m_$(dut_name)_env_$(env_cfg_name).m_$(uvc_name)_$(cfg_name) = m_$(uvc_name)_$(cfg_name);\n"
    return my_str
end
gen_line_has_agent_comment(uvc_name, tabs) = begin
    env_cfg_name = class_names["config"]
    my_str = """
    $(tabs)// m_$(dut_name)_env_$(env_cfg_name).has_$(uvc_name)_agent = 0;
    """
    return my_str
end

# ****************************************************************

test_gen() = begin
    if run_test_gen == true
        output_file_setup("$(tests_dir)")
        write_file("$(tests_dir)/$(dut_name)_test_base.sv", gen_test_base())
        write_file("$(tests_dir)/$(dut_name)_test_random.sv", gen_test_random())
    end
end

# ****************************************************************

gen_test_base() = begin 
    # TODO: Make drain time depend on clk period? Or maybe a config?
    vsqr_name = class_names["vsequencer" ]
    cfg_name  = class_names["config"     ]
    vseq_inst_name = "m_vseq"
    
    env_cfg_name = config_inst_convention
    
    gen_line0(name, tabs) = gen_lines_tdefs_w_param_env(dut_name, name, tabs)
    
    my_str = """
    class $(dut_name)_test_base $(get_param_declaration(dut_name, "    "))extends uvm_test;
        
    """
    
    if env_has_params
        my_str *= """
            `uvm_component_registry($(dut_name)_test_base #(
                .$(dut_name)_params($(dut_name)_params)
            ), "$(dut_name)_test_base")
            
        """
    else
        my_str *= """
            `uvm_component_utils($(dut_name)_test_base)
            
        """
    end
    
    tdefs_list = ["$(dut_name)_env", "$(dut_name)_env_$(cfg_name)"]
    my_str *= """
        // Typedefs - begin
    $( gen_long_str(tdefs_list, "    ", gen_line0)[1:end-1] )
    """
    
    for uvc_name in uvc_names
        tdefs_list = []
        push!(tdefs_list, "$(uvc_name)_$(get_uvc_cfg_fld(uvc_name, :class_names)["config"])")
        push!(tdefs_list, "$(uvc_name)_$(get_uvc_cfg_fld(uvc_name, :class_names)["transaction"])")
        params_prefix = get_uvc_params_prefix(uvc_name)
        gen_line1(name, tabs) = gen_lines_tdefs_w_param_env(params_prefix, name, tabs)
        my_str *= """
        $( gen_long_str(tdefs_list, "    ", gen_line1)[1:end-1] )
        """
    end
    
    my_str *= """
    $( gen_vseq_tdef("base_vsequence", "    ")[1:end-1] )
    """
    my_str *= """
    $( gen_long_str(uvc_names, "    ", gen_line_vif_typedef_env)[1:end-1] )
    """
    my_str *= """
        // Typedefs - end
    """
    my_str *= """
        
        // Config objects - begin
    $( gen_long_str(uvc_names, "    ", gen_line_cfg_instance)[1:end-1] )
        // Config objects - end
        
    """
    
    my_str *= """
        // Interfaces instances - begin
    $( gen_long_str(uvc_names, "    ", gen_line_vif_instance)[1:end-1] )
        // Interfaces instances - end
        
    """
    
    my_str *= """
        // Env
        $(dut_name)_env_$(cfg_name)_t m_$(dut_name)_env_$(cfg_name);
        $(dut_name)_env_t m_$(dut_name)_env;
        
        // Virtual sequencer (re-use this with factory overrides)
        $(dut_name)_base_vsequence_t $(vseq_inst_name);
        
        uvm_objection obj;
        
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction : new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
    """
    
    my_str *= """
            // Get VIFs from database and set them for the ENV
    $( gen_long_str(uvc_names, "        ", gen_vif_config_db_tests)[1:end-1] )
    """
    
    my_str *= """
            // Create config objects
    $( gen_long_str(uvc_names, "        ", gen_line_cfg_create)[1:end-1] )
            
            // Set agents configuration
    $( gen_long_str(uvc_names, "        ", gen_line_assign_vif_to_config)[1:end-1] )
            // m_$(uvc_names[1])_cfg.has_coverage = 1'b0;
            // m_$(uvc_names[1])_cfg.is_active = UVM_PASSIVE;
            
    """
    
    my_str *= """
            // Create ENV config
            m_$(dut_name)_env_$(cfg_name) = $(dut_name)_env_$(cfg_name)_t::type_id::create(\"m_$(dut_name)_env_$(cfg_name)\");
            
            // Set ENV configuration
            // m_$(dut_name)_env_$(cfg_name).has_virtual_sequencer = 1'b1;
    """
    if env_has_coverage
        my_str *= "        // m_$(dut_name)_env_$(cfg_name).has_coverage = 1'b1;\n"
    end 
    my_str *= """
    $( gen_long_str(uvc_names, "        ", gen_line_has_agent_comment)[1:end-1] )
            
    $( gen_long_str(uvc_names, "        ", gen_line_assign_config_test)[1:end-1] )
            
    """
    if pass_config_thru_db
        my_str *= """
                // Set env config to the database
                uvm_config_db#($(dut_name)_env_$(cfg_name)_t)::set(.cntxt(this), .inst_name("m_$(dut_name)_env"), .field_name("$(env_cfg_name)"), .value(m_$(dut_name)_env_$(cfg_name)));
                
                // Create Env
                m_$(dut_name)_env = $(dut_name)_env_t::type_id::create("m_$(dut_name)_env", this);
                
        """
    else
        my_str *= """
                // Create Env
                m_$(dut_name)_env = $(dut_name)_env_t::type_id::create("m_$(dut_name)_env", this);
                
                // Assign env config
                m_$(dut_name)_env.$(env_cfg_name) = m_$(dut_name)_env_$(cfg_name);
                
        """
    end
    my_str *= """
            // Create virtual sequence
            $(vseq_inst_name) = $(dut_name)_base_vsequence_t::type_id::create("$(vseq_inst_name)");
            
            `uvm_info("$(uppercase(dut_name)) BASE TEST", "Reached the end of build phase.", UVM_HIGH)
            uvm_config_db#(int)::set(.cntxt(this), .inst_name("*"), .field_name("recording_detail"), .value(1));
        endfunction : build_phase
        
        function void end_of_elaboration_phase (uvm_phase phase);
            super.end_of_elaboration_phase(phase);
            uvm_top.print_topology();
        endfunction : end_of_elaboration_phase
        
        function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            check_config_usage();
        endfunction : check_phase
        
    """
    # my_str *= """
    #     task run_phase(uvm_phase phase);
    #         super.run_phase(phase);
    #         obj = phase.get_objection();
    #         obj.set_drain_time(this, 200ns);
    #     endtask : run_phase
        
    # """
    my_str *= """
        task pre_reset_phase(uvm_phase phase);
            $(vseq_inst_name).kill();
        endtask : pre_reset_phase
        
        task post_reset_phase(uvm_phase phase);
            $(vseq_inst_name).kill();
        endtask : post_reset_phase
        
    """
    my_str *= """
        task main_phase(uvm_phase phase);
            obj = phase.get_objection();
            obj.set_drain_time(this, 200ns);
            
            $(vseq_inst_name).set_starting_phase(phase);
            $(vseq_inst_name).start(.sequencer(m_$(dut_name)_env.m_$(dut_name)_$(vsqr_name)));
        endtask : main_phase
        
    """
    my_str *= """
    endclass : $(dut_name)_test_base
    """
    return my_str
end

gen_test_random() = begin 
    my_str = """
    class $(dut_name)_test_random $(get_param_declaration(dut_name, "    "))extends $(dut_name)_test_base $(get_param_conn(dut_name, ""));
    
    """
    if env_has_params
        my_str *= """
            `uvm_component_registry($(dut_name)_test_random $(get_param_conn(dut_name, "    ")), "$(dut_name)_test_random")
            
        """
    else
        my_str *= """
            `uvm_component_utils($(dut_name)_test_random)
            
        """
    end
    my_str *= """
    $( gen_vseq_tdef("random_vseq", "    ")[1:end-1] )
        
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction : new
        
        function void build_phase(uvm_phase phase);
            // Override transaction types, eg:
            //      original_type_name::type_id::set_type_override(override_type_name::get_type());
            //      set_type_override_by_type (original_type::get_type(), override_type::get_type());
            //      set_inst_override_by_type (original_type::get_type(), override_type::get_type(), "full_inst_path");
            
            set_type_override_by_type($(dut_name)_base_vsequence_t::get_type(), $(dut_name)_random_vseq_t::get_type());
            
            super.build_phase(phase);
            
        endfunction : build_phase
    """
    # my_str *= """
    #     /*
    #     function void build_phase(uvm_phase phase);
    #         // Override transaction types, eg:
    #         //      original_type_name::type_id::set_type_override(override_type_name::get_type());
    #         //      set_type_override_by_type (original_type::get_type(), override_type::get_type());
    #         //      set_inst_override_by_type (original_type::get_type(), override_type::get_type(), "full_inst_path");
    #         super.build_phase(phase);
            
    #         // Random sequences config - begin
    # """
    # my_str *= gen_clknrst ? "        uvm_config_wrapper::set(this, \"m_$(dut_name)_env.agent_clknrst.sequencer.run_phase\", \"default_sequence\", clknrst_reset_and_start_clk_seq::get_type());\n" : ""
    # my_str *= """
    # $( gen_long_str(uvc_names, "        ", gen_line_sequences_config) )        // Random sequences config - end
            
    #     endfunction : build_phase
    #     */
    # """
    my_str *= """
        
    endclass : $(dut_name)_test_random
    """
    return my_str
end

# ****************************************************************
