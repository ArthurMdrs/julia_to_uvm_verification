# ***********************************
# Env Codes
# ***********************************
# Creates all classes related to the environment:
# env, env_pkg, params_pkg, env_config, vsequencer and vseq_lib
# ***********************************

gen_line_uvc_instance(uvc_name, tabs) = begin
    agent_name = get_uvc_cfg_fld(uvc_name, :class_names)["agent"]
    my_str = "$(tabs)$(uvc_name)_$(agent_name)_t m_$(uvc_name)_$(agent_name);\n"
    return my_str
end
gen_line_uvc_creation(uvc_name, tabs) = begin
    agent_name = get_uvc_cfg_fld(uvc_name, :class_names)["agent"]
    my_str = """
    $(tabs)m_$(uvc_name)_$(agent_name) = $(uvc_name)_$(agent_name)_t::type_id::create("m_$(uvc_name)_$(agent_name)", this);
    """
    return my_str
end
gen_line_connect_sequencers(uvc_name, tabs, env_cfg_name) = begin
    vsqr_name = class_names["vsequencer"]
    sqr_name   = get_uvc_cfg_fld(uvc_name, :class_names)["sequencer"]
    agent_name = get_uvc_cfg_fld(uvc_name, :class_names)["agent"]
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "agent_" * get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    else
        cfg_name = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    end
    my_str = """
    $(tabs)if (m_$(env_cfg_name).has_$(uvc_name)_agent) begin
    $(tabs)    if (m_$(env_cfg_name).m_$(uvc_name)_$(cfg_name).is_active == UVM_ACTIVE) begin
    $(tabs)        m_$(dut_name)_$(vsqr_name).m_$(uvc_name)_$(sqr_name) = m_$(uvc_name)_$(agent_name).m_sequencer;
    $(tabs)    end
    $(tabs)end
    """
    return my_str
end
gen_vif_config_db_env(uvc_name, tabs, env_cfg_name) = begin
    agent_name = get_uvc_cfg_fld(uvc_name, :class_names)["agent"]
    my_str = """
    $(tabs)if(m_$(env_cfg_name).has_$(uvc_name)_agent) begin
    $(tabs)    if(uvm_config_db#($(uvc_name)_vif_t)::get(.cntxt(this), .inst_name(""), .field_name("$(uvc_name)_vif"), .value($(uvc_name)_vif)))
    $(tabs)        `uvm_info("$(uppercase(dut_name)) ENV", "$(uppercase(uvc_name)) virtual interface was successfully set!", $(verbosities["vif_set_env"]))
    $(tabs)    else
    $(tabs)        `uvm_fatal("$(uppercase(dut_name)) ENV", "No $(uppercase(uvc_name)) interface was set!")
    $(tabs)    uvm_config_db#($(uvc_name)_vif_t)::set(.cntxt(this), .inst_name("m_$(uvc_name)_$(agent_name)"), .field_name("vif"), .value($(uvc_name)_vif));
    $(tabs)end
    $(tabs)
    """
    return my_str
end
get_sb_param_conn(tabs) = begin
    if env_has_params
        @assert size(uvc_names, 1) >= 1
        tr_name = get_uvc_cfg_fld(uvc_names[1], :class_names)["transaction"]
        my_str = """
        #(
        $(tabs)    .seq_item_t($(uvc_names[1])_$(tr_name)_t),
        $(tabs)    .$(uppercase(dut_name))_ENV_PARAMS($(uppercase(dut_name))_ENV_PARAMS)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end
gen_vsqr_tdef(tabs) = begin
    vsqr_name = class_names["vsequencer"]
    my_str = """
    $(tabs)typedef $(dut_name)_$(vsqr_name) $(gen_vsqr_param_conn(tabs))$(dut_name)_$(vsqr_name)_t;
    """
    return my_str
end
get_sb_ports_conn(tabs, env_cfg_name) = begin
    sb_name = class_names["scoreboard"]
    @assert size(uvc_names, 1) >= 1
    agent_name = get_uvc_cfg_fld(uvc_names[1], :class_names)["agent"]
    my_str = """
    $(tabs)if (m_$(env_cfg_name).has_scoreboard) begin
    $(tabs)    if (m_$(env_cfg_name).has_$(uvc_names[1])_agent)
    $(tabs)        m_$(uvc_names[1])_$(agent_name).item_from_monitor_port.connect(m_$(dut_name)_$(sb_name).item_from_monitor_fifo.analysis_export);
    $(tabs)end
    """
    return my_str
end
get_rm_ports_conn(tabs, env_cfg_name) = begin
    sb_name = class_names["scoreboard"]
    rm_name = class_names["ref_model" ]
    @assert size(uvc_names, 1) >= 1
    agent_name = get_uvc_cfg_fld(uvc_names[1], :class_names)["agent"]
    my_str = """
    $(tabs)if (m_$(env_cfg_name).has_refmod) begin
    $(tabs)    if (m_$(env_cfg_name).has_$(uvc_names[1])_agent)
    $(tabs)        m_$(uvc_names[1])_$(agent_name).item_from_monitor_port.connect(m_$(dut_name)_$(rm_name).analysis_export);
    $(tabs)end
    """
    if gen_scoreboard
        my_str *= "$(tabs)if (m_$(env_cfg_name).has_refmod && m_$(env_cfg_name).has_scoreboard)\n"
        my_str *= "$(tabs)    m_$(dut_name)_$(rm_name).$(rm_name)_port.connect(m_$(dut_name)_$(sb_name).item_from_refmod_fifo.analysis_export);\n"
        my_str = """
        $(tabs)if (m_$(env_cfg_name).has_refmod && m_$(env_cfg_name).has_scoreboard) begin
        $(tabs)    m_$(dut_name)_$(rm_name).$(rm_name)_port.connect(m_$(dut_name)_$(sb_name).item_from_refmod_fifo.analysis_export);
        $(tabs)end
        """
    end
    return my_str
end
get_cov_ports_conn(tabs, env_cfg_name) = begin
    cov_name = class_names["coverage"]
    @assert size(uvc_names, 1) >= 1
    agent_name = get_uvc_cfg_fld(uvc_names[1], :class_names)["agent"]
    my_str = """
    $(tabs)if (m_$(env_cfg_name).has_coverage) begin
    $(tabs)    if (m_$(env_cfg_name).has_$(uvc_names[1])_agent)
    $(tabs)        m_$(uvc_names[1])_$(agent_name).item_from_monitor_port.connect(m_$(dut_name)_$(cov_name).analysis_export);
    $(tabs)end
    """
    return my_str
end
gen_line_cfg_config_db(uvc_name, tabs, env_cfg_name) = begin
    agent_name = get_uvc_cfg_fld(uvc_name, :class_names)["agent"]
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "agent_" * get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    else
        cfg_name = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    end
    my_str = """
    $(tabs)uvm_config_db#($(uvc_name)_$(cfg_name)_t)::set(.cntxt(this), .inst_name("m_$(uvc_name)_$(agent_name)"), .field_name("m_$(cfg_name)"), .value(m_$(uvc_name)_$(cfg_name)));
    """
    return my_str
end
gen_assign_config_to_agent(uvc_name, tabs, env_cfg_name) = begin
    agent_name = get_uvc_cfg_fld(uvc_name, :class_names)["agent"]
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "agent_" * get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    else
        cfg_name = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    end
    my_str = """
    $(tabs)m_$(uvc_name)_$(agent_name).m_$(cfg_name) = m_$(env_cfg_name).m_$(uvc_name)_$(cfg_name);
    """
    return my_str
end
gen_line_has_agent(uvc_name, tabs) = begin
    my_str = """
    $(tabs)bit has_$(uvc_name)_agent;
    """
    return my_str
end
gen_line_has_agent_assign(uvc_name, tabs) = begin
    my_str = """
    $(tabs)has_$(uvc_name)_agent = 1;
    """
    return my_str
end
gen_lines_set_config_db_and_create_agents(uvc_name, tabs, env_cfg_name) = begin
    my_str  = """
    $(tabs)if (m_$(env_cfg_name).has_$(uvc_name)_agent) begin
    $( gen_line_cfg_config_db(uvc_name, tabs*"    ", env_cfg_name)[1:end-1] )
    $( gen_line_uvc_creation(uvc_name, tabs*"    ")[1:end-1] )
    $(tabs)end
    """
    return my_str
end
gen_lines_create_agents_and_assign_config(uvc_name, tabs, env_cfg_name) = begin
    my_str  = """
    $(tabs)if (m_$(env_cfg_name).has_$(uvc_name)_agent) begin
    $( gen_line_uvc_creation(uvc_name, tabs*"    ")[1:end-1] )
    $( gen_assign_config_to_agent(uvc_name, tabs*"    ", env_cfg_name)[1:end-1] )
    $(tabs)end
    """
    return my_str
end

# ****************************************************************

env_gen() = begin
    if run_env_gen == true
        if get_usr_cfg_fld(:use_detailed_config_instances) == true
            cfg_name = "env_$(class_names["config"])"
        else
            cfg_name = "$(class_names["config"])"
        end
        vsqr_name = class_names["vsequencer"  ]
        slib_name = class_names["sequence_lib"]
        sb_name   = class_names["scoreboard"  ]
        rm_name   = class_names["ref_model"   ]
        cov_name  = class_names["coverage"    ]
        vseq_name = class_names["vsequence"   ]
        
        # Ensure target directories exist
        output_file_setup("$(env_dir)")
        output_file_setup("$(sequences_dir)"; reset_folder=false)
        
        # Collect (filepath, generator_function) pairs
        tasks = Tuple{String,Function}[]
        push!(tasks, ("$(env_dir)/$(dut_name)_env.$(class_files_extension)", gen_env_base))
        push!(tasks, ("$(env_dir)/$(dut_name)_env_pkg.sv", gen_env_pkg))
        push!(tasks, ("$(env_dir)/$(dut_name)_$(cfg_name).$(class_files_extension)", gen_env_cfg))
        if env_has_params
            push!(tasks, ("$(env_dir)/$(dut_name)_env_params_pkg.sv", gen_env_params_pkg))
        end
        push!(tasks, ("$(env_dir)/$(dut_name)_$(vsqr_name).$(class_files_extension)", gen_vsequencer))
        push!(tasks, ("$(sequences_dir)/$(dut_name)_base_$(vseq_name).$(class_files_extension)", gen_vseq_base))
        push!(tasks, ("$(sequences_dir)/$(dut_name)_random_$(vseq_name).$(class_files_extension)", gen_vseq_random))
        if gen_scoreboard
            push!(tasks, ("$(env_dir)/$(dut_name)_$(sb_name).$(class_files_extension)", gen_scoreboard_base))
        end
        if gen_refmod
            push!(tasks, ("$(env_dir)/$(dut_name)_$(rm_name).$(class_files_extension)", gen_refmod_base))
        end
        if env_has_coverage
            push!(tasks, ("$(env_dir)/$(dut_name)_$(cov_name).$(class_files_extension)", gen_env_coverage_base))
        end
        
        # Generate all files
        tasks_iter = ProgressBar(tasks)
        ProgressBars.set_description(tasks_iter, "Generating Env files:")
        for (path, genfun) in tasks_iter
            write_file(path, genfun())
        end
    end
end

# ****************************************************************

gen_env_base() = begin
    vsqr_name  = class_names["vsequencer"  ]
    slib_name  = class_names["sequence_lib"]
    cfg_name   = class_names["config"      ]
    sb_name    = class_names["scoreboard"  ]
    rm_name    = class_names["ref_model"   ]
    cov_name   = class_names["coverage"    ]
    
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        env_cfg_name = "env_$(cfg_name)"
    else
        env_cfg_name = "$(cfg_name)"
    end
    
    vif_list = []
    for uvc_name in uvc_names
        if get_uvc_cfg_fld(uvc_name, :vif_in_config) == false
            push!(vif_list, uvc_name)
        end
    end
    
    params_prefix = get_uvc_params_prefix(dut_name)
    
    my_str = """
    class $(dut_name)_env $(get_param_declaration(params_prefix, "    "))extends uvm_env;
        
    """
    
    if env_has_params
        my_str *= """
            `uvm_component_param_utils($(dut_name)_env $(get_param_conn(params_prefix, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(dut_name)_env)
        """
    end
    
    my_str *= """
        
        // Typedefs - begin
    $( gen_lines_tdefs_w_param_env(params_prefix, "$(dut_name)_$(env_cfg_name)", "    ")[1:end-1] )
    """
    
    for uvc_name in uvc_names
        tdefs_list = []
        params_prefix = get_uvc_params_prefix(uvc_name)
        agent_name = get_uvc_cfg_fld(uvc_name, :class_names)["agent"]
        tr_name    = get_uvc_cfg_fld(uvc_name, :class_names)["transaction"]
        my_str *= """
        $( gen_lines_tdefs_w_param_env(params_prefix, "$(uvc_name)_$(agent_name)", "    ")[1:end-1] )
        $( gen_lines_tdefs_w_param_env(params_prefix, "$(uvc_name)_$(tr_name)", "    ")[1:end-1] )
        """
    end
    # cfg_name = class_names["config"]
    
    # $( gen_long_str(tdefs_list, "    ", gen_lines_tdefs_w_param_env)[1:end-1] )
    my_str *="""
    $( gen_vsqr_tdef("    ")[1:end-1] )
    """
    my_str *= gen_refmod ? "    typedef $(dut_name)_$(rm_name) $(get_sb_param_conn("    "))$(dut_name)_$(rm_name)_t;\n" : ""
    my_str *= gen_scoreboard ? "    typedef $(dut_name)_$(sb_name) $(get_sb_param_conn("    "))$(dut_name)_$(sb_name)_t;\n" : ""
    my_str *= env_has_coverage ? "    typedef $(dut_name)_$(cov_name) $(get_sb_param_conn("    "))$(dut_name)_$(cov_name)_t;\n" : ""
    
    if size(vif_list, 1) != 0
        my_str *= """
        $( gen_long_str(vif_list, "    ", gen_line_vif_typedef_env)[1:end-1] )
        """
    end
    
    my_str *= """
        // Typedefs - end
        
        
    """
    
    if size(vif_list, 1) != 0
        my_str *= """
            // Interfaces instances - begin
        $( gen_long_str(vif_list, "    ", gen_line_vif_instance)[1:end-1] )
            // Interfaces instances - end
            
        """
    end
    
    my_str *= """
        // UVCs instances - begin
    $( gen_long_str(uvc_names, "    ", gen_line_uvc_instance)[1:end-1] )
        // UVCs instances - end
        
        
        // Env config
        $(dut_name)_$(env_cfg_name)_t m_$(env_cfg_name);
        
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
        endfunction : new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
    """
    
    if pass_config_thru_db
        my_str *= """
                // Get Env config
                if(uvm_config_db#($(dut_name)_$(env_cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("m_$(env_cfg_name)"), .value(m_$(env_cfg_name))))
                    `uvm_info("$(uppercase(dut_name)) ENV", "$(uppercase(dut_name)) ENV config object was successfully set!", $(verbosities["config_set_env"]))
                else
                    `uvm_fatal("$(uppercase(dut_name)) ENV", "No $(uppercase(dut_name)) ENV config object was set!")
                
        """
    else
        my_str *= """
                // Check for Env config
                if(m_$(env_cfg_name) == null)
                    `uvm_fatal("$(uppercase(dut_name)) ENV", "No $(uppercase(dut_name)) ENV config object was set!")
                
        """
    end
    
    gen_line0(uvc_name, tabs) = gen_vif_config_db_env(uvc_name, tabs, env_cfg_name)
    if size(vif_list, 1) != 0
        my_str *= """
                // Get VIFs from database and set them for the agents
        $( gen_long_str(vif_list, "        ", gen_line0)[1:end-1] )
        """
    end
    
    if pass_config_thru_db
        gen_line3(uvc_name, tabs) = gen_lines_set_config_db_and_create_agents(uvc_name, tabs, env_cfg_name)
        my_str *= """
                // Set UVC config objects to the database and create UVCs
        $( gen_long_str(uvc_names, "        ", gen_line3)[1:end-1] )
                
        """
    else
        gen_line4(uvc_name, tabs) = gen_lines_create_agents_and_assign_config(uvc_name, tabs, env_cfg_name)
        my_str *= """
                // Create UVCs and assign UVC config objects
        $( gen_long_str(uvc_names, "        ", gen_line4)[1:end-1] )
                
        """
    end
    my_str *= """
            // Create virtual sequencer
            if (m_$(env_cfg_name).has_virtual_sequencer) begin
                m_$(dut_name)_$(vsqr_name) = $(dut_name)_$(vsqr_name)_t::type_id::create("m_$(dut_name)_$(vsqr_name)", this);
                m_$(dut_name)_$(vsqr_name).m_$(env_cfg_name) = m_$(env_cfg_name);
            end
            
    """
    my_str *= gen_refmod ? """
            // Create reference model
            if (m_$(env_cfg_name).has_refmod) begin
                m_$(dut_name)_$(rm_name) = $(dut_name)_$(rm_name)_t::type_id::create("m_$(dut_name)_$(rm_name)", this);
                m_$(dut_name)_$(rm_name).m_$(env_cfg_name) = m_$(env_cfg_name);
            end
            
    """ : ""
    my_str *= gen_scoreboard ? """
            // Create scoreboard
            if (m_$(env_cfg_name).has_scoreboard) begin
                m_$(dut_name)_$(sb_name) = $(dut_name)_$(sb_name)_t::type_id::create("m_$(dut_name)_$(sb_name)", this);
                m_$(dut_name)_$(sb_name).m_$(env_cfg_name) = m_$(env_cfg_name);
            end
            
    """ : ""
    my_str *= env_has_coverage ? """
            // Create coverage collector
            if (m_$(env_cfg_name).has_coverage) begin
                m_$(dut_name)_$(cov_name) = $(dut_name)_$(cov_name)_t::type_id::create("m_$(dut_name)_$(cov_name)", this);
                m_$(dut_name)_$(cov_name).m_$(env_cfg_name) = m_$(env_cfg_name);
                `uvm_info("$(uppercase(dut_name)) ENV", "Coverage is enabled." , $(verbosities["cov_enabled"]))
            end else begin
                `uvm_info("$(uppercase(dut_name)) ENV", "Coverage is disabled." , $(verbosities["cov_enabled"]))
            end
            
    """ : ""
    my_str *= """
            `uvm_info("$(uppercase(dut_name)) ENV", "Reached the end of build phase", $(verbosities["end_build_phase"]))
        endfunction : build_phase
        
        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);
            
            // Sequencers connect - begin
            if (m_$(env_cfg_name).has_virtual_sequencer) begin
    """
    gen_line1(uvc_name, tabs) = gen_line_connect_sequencers(uvc_name, tabs, env_cfg_name)
    my_str *= """
    $( gen_long_str(uvc_names, "            ", gen_line1)[1:end-1] )
            end
            // Sequencers connect - end
            
    """
    my_str *= gen_refmod ? """
            // Make reference model connections
    $( get_rm_ports_conn("        ", env_cfg_name)[1:end-1] )
            
    """ : ""
    my_str *= gen_scoreboard ? """
            // Connect agents to scoreboard
    $( get_sb_ports_conn("        ", env_cfg_name)[1:end-1] )
            
    """ : ""
    my_str *= env_has_coverage ? """
            // Connect monitor to coverage collector
    $( get_cov_ports_conn("        ", env_cfg_name)[1:end-1] )
            
    """ : ""
    my_str *= """
        endfunction : connect_phase
        
    endclass : $(dut_name)_env
    """
    return my_str
end

# ****************************************************************

gen_env_pkg() = begin
    vseq_name = class_names["vsequence"]
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "env_$(class_names["config"])"
    else
        cfg_name = "$(class_names["config"])"
    end
    vsqr_name = class_names["vsequencer"  ]
    slib_name = class_names["sequence_lib"]
    sb_name   = class_names["scoreboard"  ]
    rm_name   = class_names["ref_model"   ]
    cov_name  = class_names["coverage"    ]
    my_str = """
    package $(dut_name)_env_pkg;
        
        import uvm_pkg::*;
        `include "uvm_macros.svh"
        
    """
    my_str *= env_has_params ? gen_line_import("$(dut_name)_env_params", "    ") : ""
    my_str *= env_has_params ? "    \n" : ""
    my_str *= """
    $( gen_long_str(uvc_names, "    ", gen_line_import_tdefs)[1:end-1] )
    
    $( gen_long_str(uvc_names, "    ", gen_line_import)[1:end-1] )
        
        `include "$(dut_name)_$(cfg_name).$(class_files_extension)"
        `include "$(dut_name)_$(vsqr_name).$(class_files_extension)"
    """
    if gen_refmod
        my_str *= "    `include \"$(dut_name)_$(rm_name).$(class_files_extension)\"\n"
    end
    if gen_scoreboard
        my_str *= "    `include \"$(dut_name)_$(sb_name).$(class_files_extension)\"\n"
    end
    if env_has_coverage
        my_str *= "    `include \"$(dut_name)_$(cov_name).$(class_files_extension)\"\n"
    end
    my_str *= """
        `include "$(dut_name)_env.$(class_files_extension)"
        
        `include "$(dut_name)_base_$(vseq_name).$(class_files_extension)"
        `include "$(dut_name)_random_$(vseq_name).$(class_files_extension)"
        
    endpackage: $(dut_name)_env_pkg
    """
    return my_str
end

# ****************************************************************

gen_line_param(param_vec::sv_params_t, tabs) = begin
    my_str = "$(tabs)$(param_vec.type) $(param_vec.name);\n"
    return my_str
end
gen_line_default_uvc_param(uvc_name, tabs) = begin
    if get_uvc_cfg_fld(uvc_name, :uvc_has_params) && !get_uvc_cfg_fld(uvc_name, :use_env_params)
        my_str = "$(tabs)$(uppercase(uvc_name))_PARAMS: $(uvc_name)_params_pkg::$(uppercase(uvc_name))_PARAMS,\n"
    else
        my_str = ""
    end
    return my_str
end
gen_param_inst(tabs) = begin
    aux_str = ""
    param_assign_str = gen_long_str(params_vec, tabs*"    ", gen_line_param_assign)
    if length(param_assign_str) != 0
        aux_str *= param_assign_str
    end
    uvc_param_str = gen_long_str(uvc_names, tabs*"    ", gen_line_default_uvc_param)
    if length(uvc_param_str) != 0
        aux_str *= uvc_param_str
    end
    
    str = ""
    str *= "$(tabs)localparam $(dut_name)_env_params_t $(uppercase(dut_name))_ENV_PARAMS = '{\n"
    str *= aux_str[1:end-2]
    str *= "\n$(tabs)};\n"
    return str
end

gen_env_params_pkg() = begin
    my_str = """
    package $(dut_name)_env_params_pkg;
        
    """
    for uvc_name in uvc_names
        if get_uvc_cfg_fld(uvc_name, :uvc_has_params) && !get_uvc_cfg_fld(uvc_name, :use_env_params)
            my_str *= gen_line_import_param_type("$(uvc_name)", "    ")
        end
    end
    my_str *= """
        
        typedef struct packed {
    $( gen_long_str(params_vec, "        ", gen_line_param)[1:end-1] )
    """
    for uvc_name in uvc_names
        if get_uvc_cfg_fld(uvc_name, :uvc_has_params) && !get_uvc_cfg_fld(uvc_name, :use_env_params)
            my_str *= "        $(uvc_name)_params_t $(uppercase(uvc_name))_PARAMS;\n"
        end
    end
    my_str *= """
        } $(dut_name)_env_params_t;
        
    """
    
    my_str *= """
    $( gen_param_inst("    ")[1:end-1] )
    """
    
    my_str *= """
        
    endpackage : $(dut_name)_env_params_pkg
    """
    return my_str
end

# ****************************************************************

gen_env_cfg() = begin
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        env_cfg_name = "env_$(class_names["config"])"
    else
        env_cfg_name = "$(class_names["config"])"
    end
    
    params_prefix = get_uvc_params_prefix(dut_name)
    
    my_str = """
    class $(dut_name)_$(env_cfg_name) $(get_param_declaration(params_prefix, "    "))extends uvm_object;
        
    """
    
    if env_has_params
        my_str *= """
            `uvm_object_param_utils($(dut_name)_$(env_cfg_name) $(get_param_conn(params_prefix, "    ")))
            
        """
    else
        my_str *= """
            `uvm_object_utils($(dut_name)_$(env_cfg_name))
            
        """
    end
    
    for uvc_name in uvc_names
        params_prefix = get_uvc_params_prefix(uvc_name)
        if get_usr_cfg_fld(:use_detailed_config_instances) == true
            cfg_name = "agent_" * get_uvc_cfg_fld(uvc_name, :class_names)["config"]
        else
            cfg_name = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
        end
        my_str *= """
        $( gen_lines_tdefs_w_param_env(params_prefix, "$(uvc_name)_$(cfg_name)", "    ")[1:end-1] )
        """
    end
    
    my_str *="""
        
    $( gen_long_str(uvc_names, "    ", gen_line_cfg_instance)[1:end-1] )
        
    $( gen_long_str(uvc_names, "    ", gen_line_has_agent)[1:end-1] )
        
        bit has_virtual_sequencer;
    """
    
    if env_has_coverage
        my_str *= "    bit has_coverage;\n"
    end
    if gen_scoreboard
        my_str *= "    bit has_scoreboard;\n"
    end
    if gen_refmod
        my_str *= "    bit has_refmod;\n"
    end
    
    my_str *="""
        
        function new (string name = "$(dut_name)_$(env_cfg_name)");
            super.new(name);
            
            has_virtual_sequencer = 1'b1;
    """
    
    if env_has_coverage
        my_str *= "        has_coverage = 1'b1;\n"
    end
    if gen_scoreboard
        my_str *= "        has_scoreboard = 1'b1;\n"
    end 
    if gen_refmod
        my_str *= "        has_refmod = 1'b1;\n"
    end 
    
    my_str *="""
            
    $( gen_long_str(uvc_names, "        ", gen_line_has_agent_assign)[1:end-1] )
        endfunction : new
        
    endclass : $(dut_name)_$(env_cfg_name)
    """
    return my_str
end

# ****************************************************************
