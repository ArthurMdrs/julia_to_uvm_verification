# ***********************************
# Agent Codes
# ***********************************
# Creates the agent class
# Instantiates sequencer, driver and monitor
# Can instantiate a coverage class with the agent_has_coverage option
# ***********************************

gen_agent_base(prefix_name) = begin 
    agent_name = get_uvc_cfg_fld(prefix_name, :class_names)["agent"      ]
    cfg_name   = get_uvc_cfg_fld(prefix_name, :class_names)["config"     ]
    mon_name   = get_uvc_cfg_fld(prefix_name, :class_names)["monitor"    ]
    drv_name   = get_uvc_cfg_fld(prefix_name, :class_names)["driver"     ]
    sqr_name   = get_uvc_cfg_fld(prefix_name, :class_names)["sequencer"  ]
    cov_name   = get_uvc_cfg_fld(prefix_name, :class_names)["coverage"   ]
    tr_name    = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    agent_has_coverage = get_uvc_cfg_fld(prefix_name, :agent_has_coverage)
    verb_dict = get_uvc_cfg_fld(prefix_name, :verbosities)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    gen_lines_tdefs_w_param_uvc(name, tabs) = gen_lines_tdefs_w_param(params_prefix, name, tabs)
    my_str = """
    class $(prefix_name)_$(agent_name) $(get_param_declaration(params_prefix, "    "))extends uvm_agent;
        
    """
    
    if get_uvc_cfg_fld(prefix_name, :uvc_has_params)
        my_str *= """
            `uvm_component_param_utils($(prefix_name)_$(agent_name) $(get_param_conn(params_prefix, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(prefix_name)_$(agent_name))
        """
    end
    
    tdefs_list = ["$(prefix_name)_$(cfg_name)", "$(prefix_name)_$(tr_name)"]
    tdefs_list_w_seq_item = ["$(prefix_name)_$(drv_name)", "$(prefix_name)_$(sqr_name)", "$(prefix_name)_$(mon_name)"]
    if agent_has_coverage
        push!(tdefs_list_w_seq_item, "$(prefix_name)_$(cov_name)")
    end
    
    my_str *= """
        
        // Typedefs - begin
    $( gen_long_str(tdefs_list, "    ", gen_lines_tdefs_w_param_uvc)[1:end-1] )
    """
    
    gen_lines(name, tabs) = gen_lines_tdefs_w_param_w_seq_item(name, prefix_name, tabs)
    my_str *= """
    $( gen_long_str(tdefs_list_w_seq_item, "    ", gen_lines)[1:end-1] )
    """
    
    if get_uvc_cfg_fld(prefix_name, :vif_in_config) == false
        my_str *= """
        $( gen_line_vif_typedef(prefix_name, "    ")[1:end-1] )
        """
    end
    
    my_str *= """
        // Typedefs - end
    """
    
    my_str *= """
        
        $(prefix_name)_$(cfg_name)_t $(config_inst_convention);
        
    """
    if get_uvc_cfg_fld(prefix_name, :vif_in_config) == false
        my_str *= """
            $(prefix_name)_vif_t vif;
        """
    end
    my_str *= """
        $(prefix_name)_$(mon_name)_t m_monitor;
        $(prefix_name)_$(drv_name)_t m_driver;
        $(prefix_name)_$(sqr_name)_t m_sequencer;
    """
    
    my_str *= agent_has_coverage ? """
        $(prefix_name)_$(cov_name)_t m_$(prefix_name)_$(cov_name);
    """ : ""
    my_str *= """
        
        uvm_analysis_port #($(prefix_name)_$(tr_name)_t) item_from_monitor_port;
        
        function new (string name, uvm_component parent);
            super.new(name, parent);
            item_from_monitor_port = new("item_from_monitor_port", this);
        endfunction : new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
    """
    
    if pass_config_thru_db
        my_str *= """
                if(uvm_config_db#($(prefix_name)_$(cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("$(config_inst_convention)"), .value($(config_inst_convention))))
                    `uvm_info("$(uppercase(prefix_name)) AGENT", "Configuration object was successfully set!", $(verb_dict["config_set_uvc"]))
                else
                    `uvm_fatal("$(uppercase(prefix_name)) AGENT", "No configuration object was set!")
                
        """
    else
        my_str *= """
                if($(config_inst_convention) == null)
                    `uvm_fatal("$(uppercase(prefix_name)) AGENT", "No configuration object was set!")
                
        """
    end
    
    if get_uvc_cfg_fld(prefix_name, :vif_in_config) == false
        my_str *= """
                if(uvm_config_db#($(prefix_name)_vif_t)::get(.cntxt(this), .inst_name(""), .field_name("vif"), .value(vif)))
                    `uvm_info("$(uppercase(prefix_name)) AGENT", "Virtual interface was successfully set!", $(verb_dict["vif_set_uvc"]))
                else
                    `uvm_fatal("$(uppercase(prefix_name)) AGENT", "No interface was set!")
                uvm_config_db#($(prefix_name)_vif_t)::set(.cntxt(this), .inst_name("*"), .field_name("vif"), .value(vif));
                
        """
    else
        my_str *= """
                if($(config_inst_convention).vif == null)
                    `uvm_fatal("$(uppercase(prefix_name)) AGENT", "No interface was set!")
                
        """
    end
    
    my_str *= """
            if ($(config_inst_convention).has_monitor == 1'b1) begin
                m_monitor = $(prefix_name)_$(mon_name)_t::type_id::create("m_monitor", this);
                m_monitor.$(config_inst_convention) = $(config_inst_convention);
            end
            if ($(config_inst_convention).is_active == UVM_ACTIVE) begin
                m_sequencer = $(prefix_name)_$(sqr_name)_t::type_id::create("m_sequencer", this);
                m_sequencer.$(config_inst_convention) = $(config_inst_convention);
                m_driver = $(prefix_name)_$(drv_name)_t::type_id::create("m_driver", this);
                m_driver.$(config_inst_convention) = $(config_inst_convention);
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Agent is active." , $(verb_dict["agent_active"]))
            end else begin
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Agent is not active." , $(verb_dict["agent_active"]))
            end
            
    """
    my_str *= agent_has_coverage ? """
            if ($(config_inst_convention).has_coverage == 1'b1) begin
                m_$(prefix_name)_$(cov_name) = $(prefix_name)_$(cov_name)_t::type_id::create("m_$(prefix_name)_$(cov_name)", this);
                m_$(prefix_name)_$(cov_name).$(config_inst_convention) = $(config_inst_convention);
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Coverage is enabled.", $(verb_dict["cov_enabled"]))
            end else begin
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Coverage is disabled.", $(verb_dict["cov_enabled"]))
            end
    """ : ""
    my_str *= """
        endfunction : build_phase
        
        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);
            
            if ($(config_inst_convention).has_monitor == 1'b1) begin
                m_monitor.item_collected_port.connect(item_from_monitor_port);
            end
            
            if ($(config_inst_convention).is_active == UVM_ACTIVE) begin
                m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
            end
            
    """
    my_str *= agent_has_coverage ? """
            if ($(config_inst_convention).has_coverage == 1'b1 && $(config_inst_convention).has_monitor == 1'b1) begin
                m_monitor.item_collected_port.connect(m_$(prefix_name)_$(cov_name).analysis_export);
            end
    """ : ""
    my_str *= """
        endfunction : connect_phase
        
        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) AGENT", "Simulation initialized", $(verb_dict["sim_init"]))
        endfunction : start_of_simulation_phase
        
    endclass : $(prefix_name)_$(agent_name)
    """
    return my_str
end

gen_clknrst_agent(prefix_name) = gen_agent_base(prefix_name)
    
# ****************************************************************
