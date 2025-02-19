# ***********************************
# Agent Codes
# ***********************************
# Creates the agent class
# Instantiates sequencer, driver and monitor
# Can instantiate a coverage class with the agent_has_coverage option
# ***********************************

gen_agent_base(prefix_name, vec) = begin 
    name = use_short_names ? short_names_dict["agent"] : "agent"
    cfg_name = use_short_names ? short_names_dict["config"     ] : long_names_dict["config"     ]
    mon_name = use_short_names ? short_names_dict["monitor"    ] : long_names_dict["monitor"    ]
    drv_name = use_short_names ? short_names_dict["driver"     ] : long_names_dict["driver"     ]
    sqr_name = use_short_names ? short_names_dict["sequencer"  ] : long_names_dict["sequencer"  ]
    cov_name = use_short_names ? short_names_dict["coverage"   ] : long_names_dict["coverage"   ]
    tr_name  = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
    my_str = """
    class $(prefix_name)_$(name) $(get_param_declaration(params_vec, dut_name, ""))extends uvm_agent;
        
    """
    
    tdefs_list = ["$(prefix_name)_$(cfg_name)", "$(prefix_name)_$(tr_name)"]
    tdefs_list_w_seq_item = ["$(prefix_name)_$(drv_name)", "$(prefix_name)_$(sqr_name)", "$(prefix_name)_$(mon_name)"]
    if agent_has_coverage
        push!(tdefs_list_w_seq_item, "$(prefix_name)_$(cov_name)")
    end
    
    my_str *= """
        // Typedefs - begin
    $( gen_long_str(tdefs_list, "    ", gen_lines_tdefs_w_param)[1:end-1] )
    """
    
    gen_lines(name, tabs) = gen_lines_tdefs_w_param_w_seq_item(name, "$(prefix_name)", tabs)
    my_str *= """
    $( gen_long_str(tdefs_list_w_seq_item, "    ", gen_lines) )    // Typedefs - end
    """
    
    my_str *= """
        
        $(prefix_name)_$(cfg_name)_t $(config_inst_convention);
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_component_param_utils_begin($(prefix_name)_$(name) $(get_param_conn("    ")[1:end-1]))
                `uvm_field_object($(config_inst_convention), UVM_ALL_ON)
            `uvm_component_utils_end
        """
    else
        my_str *= """
            `uvm_component_utils_begin($(prefix_name)_$(name))
                `uvm_field_object($(config_inst_convention), UVM_ALL_ON)
            `uvm_component_utils_end
        """
    end
    
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
        endfunction: new
        
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
            if ($(config_inst_convention).cov_control == $(uppercase(prefix_name))_COV_ENABLE) begin
                m_$(prefix_name)_$(cov_name) = $(prefix_name)_$(cov_name)_t::type_id::create("m_$(prefix_name)_$(cov_name)", this);
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Coverage is enabled." , UVM_MEDIUM)
            end else begin
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Coverage is disabled." , UVM_MEDIUM)
            end
    """ : ""
    my_str *= """
        endfunction: build_phase
        
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
            if ($(config_inst_convention).cov_control == $(uppercase(prefix_name))_COV_ENABLE && $(config_inst_convention).has_monitor == 1'b1) begin
                m_monitor.item_collected_port.connect(m_$(prefix_name)_$(cov_name).analysis_export);
            end
    """ : ""
    my_str *= """
        endfunction: connect_phase
        
        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) AGENT", "Simulation initialized", UVM_HIGH)
        endfunction: start_of_simulation_phase
        
    endclass: $(prefix_name)_$(name)
    """
    return my_str
end

gen_clknrst_agent() = gen_agent_base("clknrst", [])
    
# ****************************************************************
