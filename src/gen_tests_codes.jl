# ***********************************
# Tests Codes
# ***********************************
# Creates an example test library
# ***********************************

gen_line_sequences_config(uvc_name, tabs) = begin
    return "$(tabs)uvm_config_wrapper::set(this, \"env.agent_$(uvc_name).sequencer.run_phase\", \"default_sequence\", $(uvc_name)_random_seq::get_type());\n"
end
gen_vif_config_db_tests(uvc_name, tabs) = begin
    return """
        $(tabs)if(uvm_config_db#($(uvc_name)_vif_t)::get(.cntxt(this), .inst_name(""), .field_name("$(uvc_name)_vif"), .value($(uvc_name)_vif)))
        $(tabs)    `uvm_info("$(uppercase(dut_name)) BASE TEST", "$(uppercase(uvc_name)) virtual interface was successfully set!", UVM_MEDIUM)
        $(tabs)else
        $(tabs)    `uvm_fatal("$(uppercase(dut_name)) BASE TEST", "No $(uppercase(uvc_name)) interface was set!")
        $(tabs)uvm_config_db#($(uvc_name)_vif_t)::set(.cntxt(this), .inst_name("m_$(dut_name)_env"), .field_name("$(uvc_name)_vif"), .value($(uvc_name)_vif));
        
        """
end
gen_line_cfg_create(uvc_name, tabs) = begin
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
    restore_config()
    my_str = """
    $(tabs)m_$(uvc_name)_$(cfg_name) = $(uvc_name)_$(cfg_name)_t::type_id::create("m_$(uvc_name)_$(cfg_name)");
    """
    return my_str
end
gen_line_cfg_set(uvc_name, tabs) = begin
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
    restore_config()
    my_str = """
    $(tabs)uvm_config_db#($(uvc_name)_$(cfg_name)_t)::set(.cntxt(this), .inst_name("m_$(dut_name)_env"), .field_name("m_$(uvc_name)_$(cfg_name)"), .value(m_$(uvc_name)_$(cfg_name)));
    """
    return my_str
end

gen_vseq_tdef(vseq_name, tabs) = begin
    vsqr_name  = use_short_names ? short_names_dict["vsequencer"  ] : long_names_dict["vsequencer"  ]
    my_str = """
    $(tabs)typedef $(dut_name)_$(vseq_name) $(gen_vsqr_param_conn(tabs))$(dut_name)_$(vseq_name)_t;
    """
    return my_str
end

# ****************************************************************

test_gen() = (!run_test_gen) ? "" : begin
    output_file_setup("generated_files/test_top"; reset_folder=false)
    write_file("generated_files/test_top/$(dut_name)_test_lib.sv", gen_test_base())
end

# ****************************************************************

gen_test_base() = begin 
    # TODO: Make drain time depend on clk period? Or maybe a config?
    vsqr_name = use_short_names ? short_names_dict["vsequencer" ] : long_names_dict["vsequencer" ]
    tr_name   = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
    vseq_inst_name = "m_vseq"
    my_str = """
    class $(dut_name)_test_base $(get_param_declaration(params_vec, dut_name, "    "))extends uvm_test;
        
    """
    
    if has_paramaters
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
    
    cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
    # env_cfg_name = "m_$(dut_name)_env_$(cfg_name)"
    env_cfg_name = config_inst_convention
    tdefs_list = ["$(dut_name)_env", "$(dut_name)_env_$(cfg_name)"]
    if gen_clknrst
        push!(tdefs_list, "clknrst_$(cfg_name)")
        push!(tdefs_list, "clknrst_$(tr_name)")
    end
    for uvc in uvc_names
        include_jl("$(cwd)/UVC_parameters/$(uvc)_parameters.jl")
        cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
        tr_name = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
        push!(tdefs_list, "$(uvc)_$(cfg_name)")
        push!(tdefs_list, "$(uvc)_$(tr_name)")
    end
    restore_config()
    cfg_name = use_short_names ? short_names_dict["config"] : "config"
    tr_name = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
    
    my_str *= """
        // Typedefs - begin
    $( gen_long_str(tdefs_list, "    ", gen_lines_tdefs_w_param)[1:end-1] )
    $( gen_vseq_tdef("base_vsequence", "    ")[1:end-1] )
        // Typedefs - end
    """
    my_str *= """
        
        // Config objects - begin
    """
    my_str *= gen_clknrst ? "    clknrst_$(cfg_name)_t m_clknrst_$(cfg_name);\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "    ", gen_line_cfg_instance)[1:end-1] )
        // Config objects - end
    """
    my_str *= """
        
        // Interface instances - begin
    """
    my_str *= gen_clknrst ? "    clknrst_vif_t clknrst_vif;\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "    ", gen_line_vif_instance)[1:end-1] )
        // Interfaces instance - end
        
        // Env
        $(dut_name)_env_$(cfg_name)_t m_$(dut_name)_env_$(cfg_name);
        $(dut_name)_env_t m_$(dut_name)_env;
        
        // Virtual sequencer (re-use this with factory overrides)
        $(dut_name)_base_vsequence_t $(vseq_inst_name);
        
        uvm_objection obj;
        
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            // Get VIFs from database and set them for the ENV
    """
    my_str *= gen_clknrst ? gen_vif_config_db_tests("clknrst", "        ")[1:end-1] : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_vif_config_db_tests)[1:end-2] )
            
            // Create config objects
    """
    my_str *= gen_clknrst ? "        m_clknrst_$(cfg_name) = clknrst_$(cfg_name)_t::type_id::create(\"m_clknrst_$(cfg_name)\");\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_line_cfg_create)[1:end-1] )
            
            // Set agents configuration
            // m_$(stub_if_names[1])_cfg.has_coverage = 1'b0;
            // m_$(stub_if_names[1])_cfg.is_active = UVM_PASSIVE;
            
            // Set config objects to the database
    """
    my_str *= gen_clknrst ? "        uvm_config_db#(clknrst_$(cfg_name)_t)::set(.cntxt(this), .inst_name(\"m_$(dut_name)_env\"), .field_name(\"m_clknrst_$(cfg_name)\"), .value(m_clknrst_$(cfg_name)));\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_line_cfg_set)[1:end-1] )
            
            // Create ENV config
            m_$(dut_name)_env_$(cfg_name) = $(dut_name)_env_$(cfg_name)_t::type_id::create(\"m_$(dut_name)_env_$(cfg_name)\");
            
            // Set ENV configuration
            m_$(dut_name)_env_$(cfg_name).some_config = 10;
    """
    if env_has_coverage
        my_str *= "        m_$(dut_name)_env_$(cfg_name).has_coverage = 1'b1;\n"
    end 
    my_str *= """
            
            uvm_config_db#($(dut_name)_env_$(cfg_name)_t)::set(.cntxt(this), .inst_name("m_$(dut_name)_env"), .field_name("$(env_cfg_name)"), .value(m_$(dut_name)_env_$(cfg_name)));
            
            // Create Env
            m_$(dut_name)_env = $(dut_name)_env_t::type_id::create("m_$(dut_name)_env", this);
            
            // Create virtual sequence
            $(vseq_inst_name) = $(dut_name)_base_vsequence_t::type_id::create("$(vseq_inst_name)");
            
            `uvm_info("$(uppercase(dut_name)) BASE TEST", "Reached the end of build phase.", UVM_HIGH)
            uvm_config_db#(int)::set(.cntxt(this), .inst_name("*"), .field_name("recording_detail"), .value(1));
        endfunction
        
        function void end_of_elaboration_phase (uvm_phase phase);
            super.end_of_elaboration_phase(phase);
            uvm_top.print_topology();
        endfunction
        
        function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            check_config_usage();
        endfunction
        
    """
    # my_str *= """
    #     task run_phase(uvm_phase phase);
    #         super.run_phase(phase);
    #         obj = phase.get_objection();
    #         obj.set_drain_time(this, 200ns);
    #     endtask: run_phase
        
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
            //phase.raise_objection(this, get_type_name());
            //`uvm_info("$(uppercase(dut_name)) BASE TEST", "phase.raise_objection", UVM_HIGH)
            
            $(vseq_inst_name).set_starting_phase(phase);
            $(vseq_inst_name).start(.sequencer(m_$(dut_name)_env.m_$(dut_name)_$(vsqr_name)));
            
            //phase.drop_objection(this, get_type_name());
            //`uvm_info("$(uppercase(dut_name)) BASE TEST", "phase.drop_objection", UVM_HIGH)
        endtask : main_phase
        
    """
    my_str *= """
    endclass: $(dut_name)_test_base
    
    //==============================================================//
    
    class $(dut_name)_test_random $(get_param_declaration(params_vec, dut_name, "    "))extends $(dut_name)_test_base $(get_param_conn(""));
    
    """
    if has_paramaters
        my_str *= """
            `uvm_component_registry($(dut_name)_test_random $(get_param_conn("    ")), "$(dut_name)_test_random")
            
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
        endfunction: new
        
        function void build_phase(uvm_phase phase);
            // Override transaction types, eg:
            //      original_type_name::type_id::set_type_override(override_type_name::get_type());
            //      set_type_override_by_type (original_type::get_type(), override_type::get_type());
            //      set_inst_override_by_type (original_type::get_type(), override_type::get_type(), "full_inst_path");
            
            set_type_override_by_type($(dut_name)_base_vsequence_t::get_type(), $(dut_name)_random_vseq_t::get_type());
            
            super.build_phase(phase);
            
        endfunction: build_phase
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
    # $( gen_long_str(stub_if_names, "        ", gen_line_sequences_config) )        // Random sequences config - end
            
    #     endfunction: build_phase
    #     */
    # """
    my_str *= """
        
    endclass: $(dut_name)_test_random
    
    //==============================================================//
    """
    return my_str
end

# ****************************************************************
