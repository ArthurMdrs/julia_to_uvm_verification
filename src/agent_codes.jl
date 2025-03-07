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
    my_str = """
    class $(prefix_name)_$(agent_name) $(get_param_declaration(params_vec, dut_name, "    "))extends uvm_agent;
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_component_param_utils($(prefix_name)_$(agent_name) $(get_param_conn(dut_name, "    ")[1:end-1]))
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
    $( gen_long_str(tdefs_list, "    ", gen_lines_tdefs_w_param)[1:end-1] )
    """
    
    gen_lines(name, tabs) = gen_lines_tdefs_w_param_w_seq_item(name, prefix_name, tabs)
    my_str *= """
    $( gen_long_str(tdefs_list_w_seq_item, "    ", gen_lines)[1:end-1] )
        // Typedefs - end
    """
    
    my_str *= """
        
        $(prefix_name)_$(cfg_name)_t $(config_inst_convention);
        
    """
    
    # my_str *= """
        
    #     $(prefix_name)_vif_t vif;
    #     $(prefix_name)_$(mon_name)_t m_$(prefix_name)_$(mon_name);
    #     $(prefix_name)_$(drv_name)_t m_$(prefix_name)_$(drv_name);
    #     $(prefix_name)_$(sqr_name)_t m_$(prefix_name)_$(sqr_name);
    # """
    
    my_str *= """
        
        $(prefix_name)_vif_t vif;
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
            
            if(uvm_config_db#($(prefix_name)_$(cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("$(config_inst_convention)"), .value($(config_inst_convention))))
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Configuration object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) AGENT", "No configuration object was set!")
            uvm_config_db#($(prefix_name)_$(cfg_name)_t)::set(.cntxt(this), .inst_name("*"), .field_name("$(config_inst_convention)"), .value($(config_inst_convention)));
            
            if(uvm_config_db#($(prefix_name)_vif_t)::get(.cntxt(this), .inst_name(""), .field_name("vif"), .value(vif)))
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Virtual interface was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) AGENT", "No interface was set!")
            uvm_config_db#($(prefix_name)_vif_t)::set(.cntxt(this), .inst_name("*"), .field_name("vif"), .value(vif));
            
            if ($(config_inst_convention).has_monitor == 1'b1) begin
                m_monitor = $(prefix_name)_$(mon_name)_t::type_id::create("m_monitor", this);
            end
            if ($(config_inst_convention).is_active == UVM_ACTIVE) begin
                m_sequencer = $(prefix_name)_$(sqr_name)_t::type_id::create("m_sequencer", this);
                m_driver = $(prefix_name)_$(drv_name)_t::type_id::create("m_driver", this);
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Agent is active." , UVM_MEDIUM)
            end else begin
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Agent is not active." , UVM_MEDIUM)
            end
            
    """
    my_str *= agent_has_coverage ? """
            if ($(config_inst_convention).has_coverage == 1'b1) begin
                m_$(prefix_name)_$(cov_name) = $(prefix_name)_$(cov_name)_t::type_id::create("m_$(prefix_name)_$(cov_name)", this);
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Coverage is enabled." , UVM_MEDIUM)
            end else begin
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Coverage is disabled." , UVM_MEDIUM)
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
            `uvm_info("$(uppercase(prefix_name)) AGENT", "Simulation initialized", UVM_HIGH)
        endfunction : start_of_simulation_phase
        
    endclass : $(prefix_name)_$(agent_name)
    """
    return my_str
end

gen_clknrst_agent(prefix_name) = gen_agent_base(prefix_name)
    
# ****************************************************************
