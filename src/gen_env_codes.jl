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
    my_str = "$(tabs)m_$(uvc_name)_$(agent_name) = $(uvc_name)_$(agent_name)_t::type_id::create(\"m_$(uvc_name)_$(agent_name)\", this);\n"
    return my_str
end
# gen_line_cfg_utils(uvc_name, tabs) = begin
#     return "$(tabs)`uvm_field_object(cfg_$(uvc_name), UVM_ALL_ON)\n"
# end
gen_line_connect_sequencers(uvc_name, tabs) = begin
    vsqr_name = class_names["vsequencer"]
    sqr_name   = get_uvc_cfg_fld(uvc_name, :class_names)["sequencer"]
    agent_name = get_uvc_cfg_fld(uvc_name, :class_names)["agent"]
    cfg_name   = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    my_str = """
    $(tabs)if (m_$(uvc_name)_$(cfg_name).is_active == UVM_ACTIVE)
    $(tabs)    m_$(dut_name)_$(vsqr_name).m_$(uvc_name)_$(sqr_name) = m_$(uvc_name)_$(agent_name).m_sequencer;\n
    """
    return my_str
end
gen_vif_config_db_env(uvc_name, tabs) = begin
    agent_name = get_uvc_cfg_fld(uvc_name, :class_names)["agent"]
    return """
        $(tabs)if(uvm_config_db#($(uvc_name)_vif_t)::get(.cntxt(this), .inst_name(""), .field_name("$(uvc_name)_vif"), .value($(uvc_name)_vif)))
        $(tabs)    `uvm_info("$(uppercase(dut_name))) ENV", "$(uppercase(uvc_name)) virtual interface was successfully set!", UVM_MEDIUM)
        $(tabs)else
        $(tabs)    `uvm_fatal("$(uppercase(dut_name))) ENV", "No $(uppercase(uvc_name)) interface was set!")
        $(tabs)uvm_config_db#($(uvc_name)_vif_t)::set(.cntxt(this), .inst_name("m_$(uvc_name)_$(agent_name)"), .field_name("vif"), .value($(uvc_name)_vif));
        $(tabs)
        """
end
gen_cfg_config_db_env(uvc_name, tabs) = begin
    agent_name = get_uvc_cfg_fld(uvc_name, :class_names)["agent"]
    cfg_name   = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    return """
    $(tabs)if(uvm_config_db#($(uvc_name)_$(cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("m_$(uvc_name)_$(cfg_name)"), .value(m_$(uvc_name)_$(cfg_name))))
    $(tabs)    `uvm_info("$(uppercase(dut_name))) ENV", "$(uppercase(uvc_name)) config object was successfully set!", UVM_MEDIUM)
    $(tabs)else
    $(tabs)    `uvm_fatal("$(uppercase(dut_name))) ENV", "No $(uppercase(uvc_name)) config object was set!")
    $(tabs)uvm_config_db#($(uvc_name)_$(cfg_name)_t)::set(.cntxt(this), .inst_name("m_$(uvc_name)_$(agent_name)"), .field_name("$(config_inst_convention)"), .value(m_$(uvc_name)_$(cfg_name)));
    $(tabs)
    """
end
get_sb_param_conn(tabs) = begin
    if has_paramaters
        @assert size(uvc_names, 1) >= 1
        tr_name = get_uvc_cfg_fld(uvc_names[1], :class_names)["transaction"]
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
    vsqr_name = class_names["vsequencer"]
    my_str = """
    $(tabs)typedef $(dut_name)_$(vsqr_name) $(gen_vsqr_param_conn(tabs))$(dut_name)_$(vsqr_name)_t;
    """
    return my_str
end
get_sb_ports_conn() = begin
    sb_name = class_names["scoreboard"]
    @assert size(uvc_names, 1) >= 1
    agent_name = get_uvc_cfg_fld(uvc_names[1], :class_names)["agent"]
    my_str = "m_$(uvc_names[1])_$(agent_name).item_from_monitor_port.connect(m_$(dut_name)_$(sb_name).item_from_monitor_fifo.analysis_export);"
    return my_str
end
get_rm_ports_conn(tabs) = begin
    sb_name = class_names["scoreboard"]
    rm_name = class_names["ref_model" ]
    @assert size(uvc_names, 1) >= 1
    agent_name = get_uvc_cfg_fld(uvc_names[1], :class_names)["agent"]
    my_str = "$(tabs)m_$(uvc_names[1])_$(agent_name).item_from_monitor_port.connect(m_$(dut_name)_$(rm_name).analysis_export);\n"
    if gen_scoreboard
        my_str *= "$(tabs)m_$(dut_name)_$(rm_name).$(rm_name)_port.connect(m_$(dut_name)_$(sb_name).item_from_refmod_fifo.analysis_export);\n"
    end
    return my_str
end
get_cov_ports_conn(tabs) = begin
    cov_name = class_names["coverage"]
    @assert size(uvc_names, 1) >= 1
    agent_name = get_uvc_cfg_fld(uvc_names[1], :class_names)["agent"]
    # my_str = """
    # $(tabs)if ($(config_inst_convention).has_coverage) begin
    # $(tabs)    m_$(uvc_names[1])_$(agent_name).item_from_monitor_port.connect(m_$(dut_name)_$(cov_name).analysis_export);
    # $(tabs)end
    # """
    my_str = """
    $(tabs)if ($(config_inst_convention).has_coverage)
    $(tabs)    m_$(uvc_names[1])_$(agent_name).item_from_monitor_port.connect(m_$(dut_name)_$(cov_name).analysis_export);
    """
    return my_str
end

# ****************************************************************

env_gen() = begin
    if run_env_gen == true
        cfg_name  = class_names["config"]
        vsqr_name = class_names["vsequencer"]
        slib_name = class_names["sequence_lib"]
        sb_name   = class_names["scoreboard"]
        rm_name   = class_names["ref_model"]
        cov_name  = class_names["coverage"]
        
        output_file_setup("$(env_dir)")
        output_file_setup("$(sequences_dir)"; reset_folder=false)
        
        write_file("$(env_dir)/$(dut_name)_env.sv", gen_env_base())
        write_file("$(env_dir)/$(dut_name)_env_pkg.sv", gen_env_pkg())
        write_file("$(env_dir)/$(dut_name)_env_$(cfg_name).sv", gen_env_cfg())
        if has_paramaters 
            write_file("$(env_dir)/$(dut_name)_params_pkg.sv", gen_params_pkg())
        end
        write_file("$(env_dir)/$(dut_name)_$(vsqr_name).sv", gen_vsequencer())
        write_file("$(sequences_dir)/$(dut_name)_base_vsequence.sv", gen_vseq_base())
        write_file("$(sequences_dir)/$(dut_name)_random_vseq.sv", gen_vseq_random())
        if gen_scoreboard 
            write_file("$(env_dir)/$(dut_name)_$(sb_name).sv", gen_scoreboard_base())
        end
        if gen_refmod
            write_file("$(env_dir)/$(dut_name)_$(rm_name).sv", gen_refmod_base())
        end
        if env_has_coverage
            write_file("$(env_dir)/$(dut_name)_$(cov_name).sv", gen_env_coverage_base())
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
    my_str = """
    class $(dut_name)_env $(get_param_declaration(params_vec, dut_name, "    "))extends uvm_env;
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_component_param_utils($(dut_name)_env $(get_param_conn(dut_name, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(dut_name)_env)
        """
    end
    
    # env_cfg_name = "m_$(dut_name)_env_$(cfg_name)"
    env_cfg_name = config_inst_convention
    tdefs_list = ["$(dut_name)_env_$(cfg_name)"]
    for uvc_name in uvc_names
        agent_name = get_uvc_cfg_fld(uvc_name, :class_names)["agent"]
        cfg_name   = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
        tr_name    = get_uvc_cfg_fld(uvc_name, :class_names)["transaction"]
        push!(tdefs_list, "$(uvc_name)_$(agent_name)")
        push!(tdefs_list, "$(uvc_name)_$(cfg_name)")
        push!(tdefs_list, "$(uvc_name)_$(tr_name)")
    end
    
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
        
    
        // Config objects - begin
    """
    my_str *= """
    $( gen_long_str(uvc_names, "    ", gen_line_cfg_instance)[1:end-1] )
        // Config objects - end
    """
    my_str *= """

        // Interfaces instances - begin
    """
    my_str *= """
    $( gen_long_str(uvc_names, "    ", gen_line_vif_instance)[1:end-1] )
        // Interfaces instances - end

        // UVCs instances - begin
    """
    my_str *= """
    $( gen_long_str(uvc_names, "    ", gen_line_uvc_instance)[1:end-1] )
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
        endfunction : new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            // Get VIFs from database and set them for the agents
    """
    
    my_str *= """
    $( gen_long_str(uvc_names, "        ", gen_vif_config_db_env)[1:end-1] )
            
            // Get config objects from database and set them for the agents
    """
    my_str *= """
    $( gen_long_str(uvc_names, "        ", gen_cfg_config_db_env)[1:end-1] )
            
            // Get Env config
            if(uvm_config_db#($(dut_name)_env_$(cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("$(env_cfg_name)"), .value($(env_cfg_name))))
                `uvm_info("$(uppercase(dut_name))) ENV", "$(uppercase(dut_name))) ENV config object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(dut_name))) ENV", "No $(uppercase(dut_name))) ENV config object was set!")
            
            // UVCs creation - begin
    """
    my_str *= """
    $( gen_long_str(uvc_names, "        ", gen_line_uvc_creation)[1:end-1] )
            // UVCs creation - end
            
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
            `uvm_info("$(uppercase(dut_name))) ENV", "Reached the end of build phase", UVM_HIGH)
        endfunction : build_phase

        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);
            
            // Sequencers connect - begin
    """
    my_str *= """
    $( gen_long_str(uvc_names, "        ", gen_line_connect_sequencers)[1:end-2] )
            // Sequencers connect - end
            
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
        endfunction : connect_phase

    endclass : $(dut_name)_env
    """
    return my_str
end

# ****************************************************************

gen_env_pkg() = begin
    cfg_name  = class_names["config"      ]
    vsqr_name = class_names["vsequencer"  ]
    slib_name = class_names["sequence_lib"]
    sb_name   = class_names["scoreboard"  ]
    rm_name   = class_names["ref_model"   ]
    cov_name  = class_names["coverage"    ]
    my_str = """
    package $(dut_name)_env_pkg;

        import uvm_pkg::*;
        `include "uvm_macros.svh"
        
        // `include "$(dut_name)_tdefs.sv"
        
    """
    my_str *= has_paramaters ? gen_line_import("$(dut_name)_params", "    ") : ""
    my_str *= has_paramaters ? "    \n" : ""
    my_str *= """
    $( gen_long_str(uvc_names, "    ", gen_line_import_tdefs)[1:end-1] )
    $( gen_long_str(uvc_names, "    ", gen_line_import)[1:end-1] )
        
        `include "$(dut_name)_env_$(cfg_name).sv"
        `include "$(dut_name)_$(vsqr_name).sv"
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
        
        `include "$(dut_name)_base_vsequence.sv"
        `include "$(dut_name)_random_vseq.sv"
                
    endpackage: $(dut_name)_env_pkg
    """
    return my_str
end

# ****************************************************************

gen_line_param(param_vec::sv_params_t, tabs) = begin
    my_str = "$(tabs)$(param_vec.type) $(param_vec.name);\n"
    return my_str
end
gen_line_param_assign(param_vec::sv_params_t, tabs) = begin
    my_str = "$(tabs)$(param_vec.name): $(param_vec.default_val),\n"
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
    $( gen_long_str(params_vec, "        ", gen_line_param)[1:end-1] )
        } $(dut_name)_params_t;
        
    """
    
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
    cfg_name = class_names["config"]
    my_str = """
    class $(dut_name)_env_$(cfg_name) $(get_param_declaration(params_vec, dut_name, "    "))extends uvm_object;
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_object_param_utils($(dut_name)_env_$(cfg_name) $(get_param_conn(dut_name, "    ")))
            
        """
    else
        my_str *= """
            `uvm_object_utils($(dut_name)_env_$(cfg_name))
            
        """
    end
    
    if env_has_coverage
        my_str *= "    bit has_coverage;\n"
    end 
    my_str *="""
        int some_config;
        
        function new (string name = "$(dut_name)_env_$(cfg_name)");
            super.new(name);
    """
    if env_has_coverage
        my_str *= "    has_coverage = 1'b1;\n"
    end 
    my_str *="""
            some_config = 0;
        endfunction : new

    endclass : $(dut_name)_env_$(cfg_name)
    """
    return my_str
end

# ****************************************************************
