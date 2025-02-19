# ***********************************
# Env Codes
# ***********************************
# Creates all classes related to the environment:
# env, env_pkg, params_pkg, env_config, vsequencer and vseq_lib
# ***********************************

gen_line_uvc_instance(uvc_name, tabs) = begin
    my_str = "$(tabs)$(uvc_name)_agent_t m_$(uvc_name)_agent;\n"
    return my_str
end
gen_line_uvc_creation(uvc_name, tabs) = begin
    my_str = "$(tabs)m_$(uvc_name)_agent = $(uvc_name)_agent_t::type_id::create(\"m_$(uvc_name)_agent\", this);\n"
    return my_str
end
gen_line_cfg_utils(uvc_name, tabs) = begin
    return "$(tabs)`uvm_field_object(cfg_$(uvc_name), UVM_ALL_ON)\n"
end
gen_line_import_tdefs(uvc_name, tabs) = begin
    return """
    $(tabs)import $(uvc_name)_tdefs_pkg::*;
    """
end
gen_line_connect_sequencers(uvc_name, tabs) = begin
    vsqr_name = use_short_names ? short_names_dict["vsequencer"] : long_names_dict["vsequencer"]
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    sqr_name = use_short_names ? short_names_dict["sequencer"] : long_names_dict["sequencer"]
    agent_name = use_short_names ? short_names_dict["agent"] : long_names_dict["agent"]
    restore_config()
    my_str = "$(tabs)m_$(dut_name)_$(vsqr_name).m_$(uvc_name)_$(sqr_name) = m_$(uvc_name)_$(agent_name).m_sequencer;\n"
    return my_str
end
gen_vif_config_db_env(uvc_name, tabs) = begin
    return """
        $(tabs)if(uvm_config_db#($(uvc_name)_vif_t)::get(.cntxt(this), .inst_name(""), .field_name("$(uvc_name)_vif"), .value($(uvc_name)_vif)))
        $(tabs)    `uvm_info("$(uppercase(dut_name)) ENV", "$(uppercase(uvc_name)) virtual interface was successfully set!", UVM_MEDIUM)
        $(tabs)else
        $(tabs)    `uvm_fatal("$(uppercase(dut_name)) ENV", "No $(uppercase(uvc_name)) interface was set!")
        $(tabs)uvm_config_db#($(uvc_name)_vif_t)::set(.cntxt(this), .inst_name("m_$(uvc_name)_agent"), .field_name("vif"), .value($(uvc_name)_vif));
        $(tabs)
        """
end
gen_cfg_config_db_env(uvc_name, tabs) = begin
    cwd = pwd()
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
    restore_config()
    return """
    $(tabs)if(uvm_config_db#($(uvc_name)_$(cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("m_$(uvc_name)_$(cfg_name)"), .value(m_$(uvc_name)_$(cfg_name))))
    $(tabs)    `uvm_info("$(uppercase(dut_name)) ENV", "$(uppercase(uvc_name)) config object was successfully set!", UVM_MEDIUM)
    $(tabs)else
    $(tabs)    `uvm_fatal("$(uppercase(dut_name)) ENV", "No $(uppercase(uvc_name)) config object was set!")
    $(tabs)uvm_config_db#($(uvc_name)_$(cfg_name)_t)::set(.cntxt(this), .inst_name("m_$(uvc_name)_agent"), .field_name("$(config_inst_convention)"), .value(m_$(uvc_name)_$(cfg_name)));
    $(tabs)
    """
end
get_sb_param_conn(tabs) = begin
    if has_paramaters
        @assert size(uvc_names, 1) >= 1
        include_jl("$(cwd)/UVC_parameters/$(uvc_names[1])_parameters.jl")
        tr_name = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
        restore_config()
        my_str = """
        #(
        $(tabs)    .seq_item_t($(uvc_names[1])_$(tr_name)_t),
        $(tabs)    .$(dut_name)_params($(dut_name)_params)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end
gen_vsqr_tdef(tabs) = begin
    vsqr_name  = use_short_names ? short_names_dict["vsequencer"  ] : long_names_dict["vsequencer"  ]
    my_str = """
    $(tabs)typedef $(dut_name)_$(vsqr_name) $(gen_vsqr_param_conn(tabs))$(dut_name)_$(vsqr_name)_t;
    """
    return my_str
end
get_sb_ports_conn() = begin
    sb_name = use_short_names ? short_names_dict["scoreboard"] : long_names_dict["scoreboard"]
    @assert size(uvc_names, 1) >= 1
    include_jl("$(cwd)/UVC_parameters/$(uvc_names[1])_parameters.jl")
    agent_name = use_short_names ? short_names_dict["agent"] : long_names_dict["agent"]
    restore_config()
    my_str = "m_$(uvc_names[1])_$(agent_name).item_from_monitor_port.connect(m_$(dut_name)_$(sb_name).item_from_monitor_fifo.analysis_export);"
    return my_str
end
get_rm_ports_conn(tabs) = begin
    sb_name = use_short_names ? short_names_dict["scoreboard"] : long_names_dict["scoreboard"]
    rm_name = use_short_names ? short_names_dict["ref_model" ] : long_names_dict["ref_model" ]
    @assert size(uvc_names, 1) >= 1
    include_jl("$(cwd)/UVC_parameters/$(uvc_names[1])_parameters.jl")
    agent_name = use_short_names ? short_names_dict["agent"] : long_names_dict["agent"]
    restore_config()
    my_str = "$(tabs)m_$(uvc_names[1])_$(agent_name).item_from_monitor_port.connect(m_$(dut_name)_$(rm_name).analysis_export);\n"
    if gen_scoreboard
        my_str *= "$(tabs)m_$(dut_name)_$(rm_name).$(rm_name)_port.connect(m_$(dut_name)_$(sb_name).item_from_refmod_fifo.analysis_export);\n"
    end
    return my_str
end
get_cov_ports_conn(tabs) = begin
    cov_name = use_short_names ? short_names_dict["coverage"] : long_names_dict["coverage"]
    @assert size(uvc_names, 1) >= 1
    include_jl("$(cwd)/UVC_parameters/$(uvc_names[1])_parameters.jl")
    agent_name = use_short_names ? short_names_dict["agent"] : long_names_dict["agent"]
    restore_config()
    my_str = """
    $(tabs)if ($(config_inst_convention).has_coverage) begin
    $(tabs)    m_$(uvc_names[1])_$(agent_name).item_from_monitor_port.connect(m_$(dut_name)_$(cov_name).analysis_export);
    $(tabs)end
    """
    return my_str
end

# ****************************************************************

env_gen() = (!run_env_gen) ? "" : begin
    output_file_setup("generated_files/test_top"; reset_folder=false)
    write_file("generated_files/test_top/$(dut_name)_env.sv", gen_env_base())
    write_file("generated_files/test_top/$(dut_name)_env_pkg.sv", gen_env_pkg())
    cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
    write_file("generated_files/test_top/$(dut_name)_env_$(cfg_name).sv", gen_env_cfg())
    if has_paramaters 
        write_file("generated_files/test_top/$(dut_name)_params_pkg.sv", gen_params_pkg())
    end
    vsqr_name = use_short_names ? short_names_dict["vsequencer"] : long_names_dict["vsequencer"]
    write_file("generated_files/test_top/$(dut_name)_$(vsqr_name).sv", gen_vsequencer())
    slib_name = use_short_names ? short_names_dict["sequence_lib"] : long_names_dict["sequence_lib"]
    write_file("generated_files/test_top/$(dut_name)_v$(slib_name).sv", gen_vseq_lib())
    sb_name = use_short_names ? short_names_dict["scoreboard"] : long_names_dict["scoreboard"]
    if gen_scoreboard 
        write_file("generated_files/test_top/$(dut_name)_$(sb_name).sv", gen_scoreboard_base())
    end
    rm_name = use_short_names ? short_names_dict["ref_model"] : long_names_dict["ref_model"]
    if gen_refmod
        write_file("generated_files/test_top/$(dut_name)_$(rm_name).sv", gen_refmod_base())
    end
    cov_name = use_short_names ? short_names_dict["coverage"] : long_names_dict["coverage"]
    if env_has_coverage
        write_file("generated_files/test_top/$(dut_name)_$(cov_name).sv", gen_env_coverage_base())
    end
end

# ****************************************************************

gen_env_base() = begin
    vsqr_name  = use_short_names ? short_names_dict["vsequencer"  ] : long_names_dict["vsequencer"  ]
    slib_name  = use_short_names ? short_names_dict["sequence_lib"] : long_names_dict["sequence_lib"]
    sqr_name   = use_short_names ? short_names_dict["sequencer"   ] : long_names_dict["sequencer"   ]
    agent_name = use_short_names ? short_names_dict["agent"       ] : long_names_dict["agent"       ]
    cfg_name   = use_short_names ? short_names_dict["config"      ] : long_names_dict["config"      ]
    tr_name    = use_short_names ? short_names_dict["transaction" ] : long_names_dict["transaction" ]
    sb_name    = use_short_names ? short_names_dict["scoreboard"  ] : long_names_dict["scoreboard"  ]
    rm_name    = use_short_names ? short_names_dict["ref_model"   ] : long_names_dict["ref_model"   ]
    cov_name   = use_short_names ? short_names_dict["coverage"    ] : long_names_dict["coverage"    ]
    my_str = """
    class $(dut_name)_env $(get_param_declaration(params_vec, dut_name, ""))extends uvm_env;
        
    """
    
    # env_cfg_name = "m_$(dut_name)_env_$(cfg_name)"
    env_cfg_name = config_inst_convention
    tdefs_list = ["$(dut_name)_env_$(cfg_name)"]
    if gen_clknrst
        push!(tdefs_list, "clknrst_agent")
        push!(tdefs_list, "clknrst_$(cfg_name)")
        push!(tdefs_list, "clknrst_$(tr_name)")
    end
    for uvc in stub_if_names
        include_jl("$(cwd)/UVC_parameters/$(uvc)_parameters.jl")
        agent_name = use_short_names ? short_names_dict["agent"] : long_names_dict["agent"]
        cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
        tr_name = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
        push!(tdefs_list, "$(uvc)_$(agent_name)")
        push!(tdefs_list, "$(uvc)_$(cfg_name)")
        push!(tdefs_list, "$(uvc)_$(tr_name)")
    end
    restore_config()
    sqr_name   = use_short_names ? short_names_dict["sequencer"   ] : long_names_dict["sequencer"   ]
    agent_name = use_short_names ? short_names_dict["agent"       ] : long_names_dict["agent"       ]
    cfg_name   = use_short_names ? short_names_dict["config"      ] : long_names_dict["config"      ]
    tr_name    = use_short_names ? short_names_dict["transaction" ] : long_names_dict["transaction" ]
    
    my_str *= """
        // Typedefs - begin
    $( gen_long_str(tdefs_list, "    ", gen_lines_tdefs_w_param)[1:end-1] )
    $( gen_vsqr_tdef("    ")[1:end-1] )
    """
    my_str *= gen_refmod ? "    typedef $(dut_name)_$(rm_name) $(get_sb_param_conn("    "))$(dut_name)_$(rm_name)_t;\n" : ""
    my_str *= gen_scoreboard ? "    typedef $(dut_name)_$(sb_name) $(get_sb_param_conn("    "))$(dut_name)_$(sb_name)_t;\n" : ""
    my_str *= env_has_coverage ? "    typedef $(dut_name)_$(cov_name) $(get_sb_param_conn("    "))$(dut_name)_$(cov_name)_t;\n" : ""
    my_str *= """
        // Typedefs - end
        
        // Env config
    """
    my_str *= """
        $(dut_name)_env_$(cfg_name)_t $(env_cfg_name);
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_component_param_utils_begin($(dut_name)_env $(get_param_conn("    ")[1:end-1]))
                `uvm_field_object($(env_cfg_name), UVM_ALL_ON)
            `uvm_component_utils_end
        """
    else
        my_str *= """
            `uvm_component_utils_begin($(dut_name)_env)
                `uvm_field_object($(env_cfg_name), UVM_ALL_ON)
            `uvm_component_utils_end
        """
    end
    
    my_str *= """
    
        // Config objects - begin
    """
    my_str *= gen_clknrst ? "    clknrst_$(cfg_name)_t m_clknrst_$(cfg_name);\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "    ", gen_line_cfg_instance)[1:end-1] )
        // Config objects - end
    """
    my_str *= """

        // Interfaces instances - begin
    """
    my_str *= gen_clknrst ? "    clknrst_vif_t clknrst_vif;\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "    ", gen_line_vif_instance)[1:end-1] )
        // Interfaces instances - end

        // UVCs instances - begin
    """
    my_str *= gen_clknrst ? "    clknrst_agent_t m_clknrst_agent;\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "    ", gen_line_uvc_instance)[1:end-1] )
        // UVCs instances - end 
        
        // Virtual Sequencer
        $(dut_name)_$(vsqr_name)_t m_$(dut_name)_$(vsqr_name);
        
    """
    my_str *= gen_refmod ? """
        // Reference model
        $(dut_name)_$(rm_name)_t m_$(dut_name)_$(rm_name);
        
    """ : ""
    my_str *= gen_scoreboard ? """
        // Scoreboard
        $(dut_name)_$(sb_name)_t m_$(dut_name)_$(sb_name);
        
    """ : ""
    my_str *= env_has_coverage ? """
        // Coverage collector
        $(dut_name)_$(cov_name)_t m_$(dut_name)_$(cov_name);
        
    """ : ""
    my_str *= """
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            // Get VIFs from database and set them for the agents
    """
    
    my_str *= gen_clknrst ? gen_vif_config_db_env("clknrst", "        ") : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_vif_config_db_env) )
            // Get config objects from database and set them for the agents
    """
    my_str *= gen_clknrst ? """
            if(uvm_config_db#(clknrst_$(cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("m_clknrst_$(cfg_name)"), .value(m_clknrst_$(cfg_name))))
                `uvm_info("$(uppercase(dut_name)) ENV", "$(uppercase("clknrst")) config object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(dut_name)) ENV", "No $(uppercase("clknrst")) config object was set!")
            uvm_config_db#(clknrst_$(cfg_name)_t)::set(.cntxt(this), .inst_name("m_clknrst_agent"), .field_name("$(config_inst_convention)"), .value(m_clknrst_$(cfg_name)));
            
    """ : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_cfg_config_db_env) )
            // Get Env config
            if(uvm_config_db#($(dut_name)_env_$(cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("$(env_cfg_name)"), .value($(env_cfg_name))))
                `uvm_info("$(uppercase(dut_name)) ENV", "$(uppercase(dut_name)) ENV config object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(dut_name)) ENV", "No $(uppercase(dut_name)) ENV config object was set!")
            
            // UVCs creation - begin
    """
    my_str *= gen_clknrst ? gen_line_uvc_creation("clknrst", "        ") : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_line_uvc_creation) )        // UVCs creation - end
            
            // Set config to virtual sequencer
            uvm_config_db#($(dut_name)_env_$(cfg_name)_t)::set(.cntxt(this), .inst_name("m_$(dut_name)_$(vsqr_name)"), .field_name("$(config_inst_convention)"), .value($(env_cfg_name)));
            
            // Create virtual sequencer
            m_$(dut_name)_$(vsqr_name) = $(dut_name)_$(vsqr_name)_t::type_id::create("m_$(dut_name)_$(vsqr_name)", this);
            
    """
    my_str *= gen_refmod ? """
            // Create reference model
            m_$(dut_name)_$(rm_name) = $(dut_name)_$(rm_name)_t::type_id::create("m_$(dut_name)_$(rm_name)", this);
            
    """ : ""
    my_str *= gen_scoreboard ? """
            // Create scoreboard
            m_$(dut_name)_$(sb_name) = $(dut_name)_$(sb_name)_t::type_id::create("m_$(dut_name)_$(sb_name)", this);
            
    """ : ""
    my_str *= env_has_coverage ? """
            // Create coverage collector
            if ($(env_cfg_name).has_coverage) begin
                m_$(dut_name)_$(cov_name) = $(dut_name)_$(cov_name)_t::type_id::create("m_$(dut_name)_$(cov_name)", this);
                `uvm_info("$(uppercase(dut_name)) ENV", "Coverage is enabled." , UVM_MEDIUM)
            end else begin
                `uvm_info("$(uppercase(dut_name)) ENV", "Coverage is disabled." , UVM_MEDIUM)
            end
            
    """ : ""
    my_str *= """
            `uvm_info("$(uppercase(dut_name)) ENV", "Reached the end of build phase", UVM_HIGH)
        endfunction

        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);
            
            // Sequencers connect - begin$(gen_clknrst ? "\n        m_$(dut_name)_$(vsqr_name).m_clknrst_$(sqr_name) = m_clknrst_$(agent_name).m_sequencer;" : "")
    $( gen_long_str(stub_if_names, "        ", gen_line_connect_sequencers) )        // Sequencers connect - end
            
    """
    my_str *= gen_refmod ? """
            // Make reference model connections
    $(get_rm_ports_conn("        ")[1:end-1])
            
    """ : ""
    my_str *= gen_scoreboard ? """
            // Connect agents to scoreboard
            $(get_sb_ports_conn())
            
    """ : ""
    my_str *= env_has_coverage ? """
            // Connect monitor to coverage collector
    $(get_cov_ports_conn("        ")[1:end-1])
            
    """ : ""
    my_str *= """
        endfunction: connect_phase

    endclass: $(dut_name)_env
    """
    return my_str
end

# ****************************************************************

gen_env_pkg() = begin
    cfg_name  = use_short_names ? short_names_dict["config"      ] : long_names_dict["config"      ]
    vsqr_name = use_short_names ? short_names_dict["vsequencer"  ] : long_names_dict["vsequencer"  ]
    slib_name = use_short_names ? short_names_dict["sequence_lib"] : long_names_dict["sequence_lib"]
    sb_name   = use_short_names ? short_names_dict["scoreboard"  ] : long_names_dict["scoreboard"  ]
    rm_name   = use_short_names ? short_names_dict["ref_model"   ] : long_names_dict["ref_model"   ]
    cov_name  = use_short_names ? short_names_dict["coverage"    ] : long_names_dict["coverage"    ]
    my_str = """
    package $(dut_name)_env_pkg;

        import uvm_pkg::*;
        `include "uvm_macros.svh"
        
        // `include "$(dut_name)_tdefs.sv"
        
    """
    my_str *= has_paramaters ? gen_line_import("$(dut_name)_params", "    ") : ""
    my_str *= gen_clknrst ? gen_line_import_tdefs("clknrst", "    ") : ""
    my_str *= gen_clknrst ? gen_line_import("clknrst", "    ") : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "    ", gen_line_import_tdefs)[1:end-1] )
    $( gen_long_str(stub_if_names, "    ", gen_line_import)[1:end-1] )
        
        `include "$(dut_name)_env_$(cfg_name).sv"
        `include "$(dut_name)_$(vsqr_name).sv"
        `include "$(dut_name)_v$(slib_name).sv"
    """
    if gen_refmod
        my_str *= "    `include \"$(dut_name)_$(rm_name).sv\"\n"
    end
    if gen_scoreboard
        my_str *= "    `include \"$(dut_name)_$(sb_name).sv\"\n"
    end
    if env_has_coverage
        my_str *= "    `include \"$(dut_name)_$(cov_name).sv\"\n"
    end
    my_str *= """
        `include "$(dut_name)_env.sv"
        
        `include "$(dut_name)_test_lib.sv"
                
    endpackage: $(dut_name)_env_pkg
    """
    return my_str
end

# ****************************************************************

gen_line_param(param_vec, tabs) = begin
    # my_str = "$(tabs)$(param_vec[1]) $(param_vec[2]) = $(param_vec[3]);\n"
    my_str = "$(tabs)$(param_vec[1]) $(param_vec[2]);\n"
    return my_str
end
gen_line_param_assign(param_vec, tabs) = begin
    my_str = "$(tabs)$(param_vec[2]): $(param_vec[3]),\n"
    return my_str
end
gen_param_inst(tabs) = begin
    str = ""
    if has_paramaters == true
        str *= "$(tabs)localparam $(dut_name)_params_t $(dut_name)_params = '{\n"
        str *= gen_long_str(params_vec, tabs*"    ", gen_line_param_assign)[1:end-2]
        str *= "\n$(tabs)};\n"
    end
    return str
end

gen_params_pkg() = begin
    my_str = """
    package $(dut_name)_params_pkg;
        
        typedef struct packed {
    $(gen_long_str(params_vec, "        ", gen_line_param))    } $(dut_name)_params_t;
        
    """
    
    # $(gen_long_str(params_vec, "    ", gen_line_param_field))
    my_str *= """
    $( gen_param_inst("    ") )
    """
    
    my_str *= """
    endpackage : $(dut_name)_params_pkg
    """
    return my_str
end

# ****************************************************************

gen_env_cfg() = begin
    cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
    my_str = """
    class $(dut_name)_env_$(cfg_name) $(get_param_declaration(params_vec, dut_name, ""))extends uvm_object;
        
        int some_config;
        
    """
    if env_has_coverage
        # my_str *= "    $(prefix_name)_cov_enable_enum_t cov_control;\n"
        my_str *= "    bit has_coverage;\n"
    end 
    
    if has_paramaters
        my_str *= """
            `uvm_object_param_utils_begin($(dut_name)_env_$(cfg_name) $(get_param_conn("    ")))
                `uvm_field_int(some_config, UVM_ALL_ON)
            `uvm_object_utils_end
            
        """
    else
        my_str *= """
            `uvm_object_utils_begin($(dut_name)_env_$(cfg_name))
                `uvm_field_int(some_config, UVM_ALL_ON)
            `uvm_object_utils_end
            
        """
    end
    my_str *="""

        function new (string name = "$(dut_name)_env_$(cfg_name)");
            super.new(name);
            some_config = 0;
        endfunction: new

    endclass: $(dut_name)_env_$(cfg_name)
    """
    return my_str
end

# ****************************************************************

gen_line_seq_item_t_decl(uvc_name, tabs) = begin
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    tr_name  = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
    restore_config()
    my_str = "$(tabs)parameter type $(uvc_name)_$(tr_name)_t = uvm_sequence_item,\n"
    return my_str
end
get_vsqr_param_declaration(tabs) = begin
    my_str = ""
    if has_paramaters
        gen_line(param_vec, tabs) = "$(tabs)$(param_vec[2]): $(param_vec[3]),\n"
        tr_name  = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
        clknrst_line = gen_clknrst ? "\n$(tabs)parameter type clknrst_$(tr_name)_t = uvm_sequence_item," : ""
        my_str *= """
        #($(clknrst_line)
        $(gen_long_str(stub_if_names, tabs, gen_line_seq_item_t_decl)[1:end-1])
        $(tabs)parameter $(dut_name)_params_t $(dut_name)_params = '{
        $(gen_long_str(params_vec, tabs*"    ", gen_line)[1:end-2])
        $(tabs)}
        ) """
    end
    return my_str
end
get_vsqr_param_conn(tabs) = begin
    if has_paramaters
        tr_name  = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
        clknrst_line = gen_clknrst ? "\n$(tabs)    .clknrst_$(tr_name)_t(clknrst_$(tr_name)_t)," : ""
        my_str = """
        #($(clknrst_line)
        $(gen_long_str(stub_if_names, tabs*"    ", gen_line_seq_item_t_conn)[1:end-1])
        $(tabs)    .$(dut_name)_params($(dut_name)_params)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end
gen_line_sqr_instance(sqr_name, tabs) = begin
    my_str = "$(tabs)$(sqr_name)_t m_$(sqr_name);\n"
    return my_str
end
gen_line_stop_seq(sqr_name, tabs) = begin
    my_str = "$(tabs)m_$(sqr_name).stop_sequences();\n"
    return my_str
end

gen_vsequencer() = begin
    vsqr_name = use_short_names ? short_names_dict["vsequencer"] : long_names_dict["vsequencer"]
    sqr_name  = use_short_names ? short_names_dict["sequencer" ] : long_names_dict["sequencer" ]
    cfg_name  = use_short_names ? short_names_dict["config"    ] : long_names_dict["config"    ]
    my_str = """
    class $(dut_name)_$(vsqr_name) $(get_vsqr_param_declaration("    "))extends uvm_sequencer;
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_component_param_utils($(dut_name)_$(vsqr_name) $(get_vsqr_param_conn("    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(dut_name)_$(vsqr_name))
        """
    end
    
    my_str *= """
        
        // Typedefs - begin
    $(gen_lines_tdefs_w_param("$(dut_name)_env_$(cfg_name)", "    ")[1:end-1])
    """
    
    sequencer_list = gen_clknrst ? ["clknrst_$(sqr_name)"] : []
    my_str *= gen_clknrst ? gen_lines_tdefs_w_param_w_seq_item("clknrst_$(sqr_name)", "clknrst", "    ") : ""
    for uvc_name in stub_if_names
        include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
        sqr_name = use_short_names ? short_names_dict["sequencer"] : long_names_dict["sequencer"]
        push!(sequencer_list, "$(uvc_name)_$(sqr_name)")
        my_str *= gen_lines_tdefs_w_param_w_seq_item("$(uvc_name)_$(sqr_name)", uvc_name, "    ")
    end
    restore_config()
    
    my_str *= """
        // Typedefs - end    
        
        // Sequencers - begin
    $( gen_long_str(sequencer_list, "    ", gen_line_sqr_instance) )    // Sequencers - end
        
        // Env config
        $(dut_name)_env_$(cfg_name)_t $(config_inst_convention);
        
        function new(string name="$(dut_name)_$(vsqr_name)", uvm_component parent = null);
            super.new(name, parent);
        endfunction: new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if(uvm_config_db#($(dut_name)_env_$(cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("$(config_inst_convention)"), .value($(config_inst_convention))))
                `uvm_info("$(uppercase(dut_name)) VSEQUENCER", "Configuration object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(dut_name)) VSEQUENCER", "No configuration object was set!")
        endfunction: build_phase

        task pre_reset_phase(uvm_phase phase);
    $( gen_long_str(sequencer_list, "        ", gen_line_stop_seq)[1:end-1] )
        endtask : pre_reset_phase

        task post_reset_phase(uvm_phase phase);
    $( gen_long_str(sequencer_list, "        ", gen_line_stop_seq)[1:end-1] )
        endtask : post_reset_phase

    endclass: $(dut_name)_$(vsqr_name)
    """
    return my_str
end

# ****************************************************************

gen_line_seq_instance(seq_name, tabs) = begin
    my_str = "$(tabs)$(seq_name)_t m_$(seq_name);\n"
    return my_str
end
gen_line_rnd_seq_creation(uvc_name, tabs) = begin
    my_str = "$(tabs)m_$(uvc_name)_random_seq = $(uvc_name)_random_seq_t::type_id::create(\"m_$(uvc_name)_random_seq\");\n"
    return my_str
end
gen_line_rnd_seq_start(uvc_name, tabs) = begin
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    sqr_name  = use_short_names ? short_names_dict["sequencer" ] : long_names_dict["sequencer" ]
    restore_config()
    my_str = "$(tabs)m_$(uvc_name)_random_seq.start(.sequencer(p_sequencer.m_$(uvc_name)_$(sqr_name)), .call_pre_post(0));\n"
    return my_str
end
    
gen_vseq_lib() = begin
    vsqr_name = use_short_names ? short_names_dict["vsequencer"] : long_names_dict["vsequencer"]
    sqr_name  = use_short_names ? short_names_dict["sequencer" ] : long_names_dict["sequencer" ]
    my_str = """
    class $(dut_name)_base_vsequence $(get_vsqr_param_declaration("    "))extends uvm_sequence;
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_object_param_utils($(dut_name)_base_vsequence $(get_vsqr_param_conn("    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_object_utils($(dut_name)_base_vsequence)
        """
    end
    
    my_str *= """
    
        // Typedefs - begin
    """
    
    seq_list = []
    if gen_clknrst
        push!(seq_list, "clknrst_start_clk_seq")
        push!(seq_list, "clknrst_stop_clk_seq")
        push!(seq_list, "clknrst_restart_clk_seq")
        push!(seq_list, "clknrst_assert_reset_seq")
        push!(seq_list, "clknrst_reset_and_start_clk_seq")
    end
    for x in seq_list
        my_str *= gen_lines_tdefs_w_param_w_seq_item(x, "clknrst", "    ")
    end
    for uvc_name in stub_if_names
        include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
        push!(seq_list, "$(uvc_name)_random_seq")
        my_str *= gen_lines_tdefs_w_param_w_seq_item("$(uvc_name)_random_seq", uvc_name, "    ")
    end
    restore_config()
    
    my_str *= """ 
    $( gen_vsqr_tdef("    ")[1:end-1] )
        // Typedefs - end 
        
        `uvm_declare_p_sequencer($(dut_name)_$(vsqr_name)_t)
        
        // Sequence instances - begin
    $( gen_long_str(seq_list, "    ", gen_line_seq_instance) )    // Sequence instances - end
        
        function new(string name="$(dut_name)_base_vsequence");
            super.new(name);
        endfunction: new
        
    """
    # my_str *= """ 
    #     task pre_body();
    #         uvm_phase phase = get_starting_phase();
    #         phase.raise_objection(this, get_type_name());
    #         `uvm_info("$(dut_name) Sequence", "phase.raise_objection", UVM_HIGH)
    #     endtask: pre_body
        
    #     task post_body();
    #         uvm_phase phase = get_starting_phase();
    #         phase.drop_objection(this, get_type_name());
    #         `uvm_info("$(dut_name) Sequence", "phase.drop_objection", UVM_HIGH)
    #     endtask: post_body
        
    # """
    my_str *= """ 
    endclass: $(dut_name)_base_vsequence
    
    //==============================================================//
    
    class $(dut_name)_random_vseq $(get_vsqr_param_declaration("    "))extends $(dut_name)_base_vsequence$(gen_vsqr_param_conn("")[1:end-1]);
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_object_param_utils($(dut_name)_random_vseq $(get_vsqr_param_conn("    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_object_utils($(dut_name)_random_vseq)
        """
    end
    
    my_str *= """
        
        function new(string name="$(dut_name)_random_vseq");
            super.new(name);
        endfunction: new
        
        virtual task body();
    """
    
    if gen_clknrst
        my_str *= "        m_clknrst_reset_and_start_clk_seq = clknrst_reset_and_start_clk_seq_t::type_id::create(\"m_clknrst_reset_and_start_clk_seq\");\n"
    else
        my_str *= ""
    end
    
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_line_rnd_seq_creation)[1:end-1] )
    """
    
    if gen_clknrst
        my_str *= "\n        m_clknrst_reset_and_start_clk_seq.start(.sequencer(p_sequencer.m_clknrst_$(sqr_name)), .call_pre_post(0));\n"
    else
        my_str *= ""
    end
    
    my_str *= """
            
            fork
    $( gen_long_str(stub_if_names, "            ", gen_line_rnd_seq_start)[1:end-1] )
            join
            
        endtask: body
        
    endclass: $(dut_name)_random_vseq
    """
    return my_str
end

