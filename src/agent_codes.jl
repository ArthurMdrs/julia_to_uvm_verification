# ***********************************
# Agent Codes!!!!!
# ***********************************
# No vector is necessary!!!
# ***********************************

gen_agent_base(prefix_name, vec) = begin 
    name = use_short_names ? short_names_dict["agent"] : "agent"
    cfg_name = use_short_names ? short_names_dict["config"     ] : "config"
    mon_name = use_short_names ? short_names_dict["monitor"    ] : "monitor"
    drv_name = use_short_names ? short_names_dict["driver"     ] : "driver"
    sqr_name = use_short_names ? short_names_dict["sequencer"  ] : "sequencer"
    cov_name = use_short_names ? short_names_dict["coverage"   ] : "cov"
    tr_name  = use_short_names ? short_names_dict["transaction"] : "transaction"
    return """
    class $(prefix_name)_$(name) extends uvm_agent;

        $(prefix_name)_$(cfg_name) cfg;
        
        //uvm_active_passive_enum is_active;
        //$(prefix_name)_cov_enable_enum cov_control;

        `uvm_component_utils_begin($(prefix_name)_$(name))
            `uvm_field_object(cfg, UVM_ALL_ON)
            //`uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
            //`uvm_field_enum($(prefix_name)_cov_enable_enum, cov_control, UVM_ALL_ON)
        `uvm_component_utils_end

        $(prefix_name)_vif     vif;
        $(prefix_name)_$(mon_name)     monitor;
        $(prefix_name)_$(drv_name)      driver;
        $(prefix_name)_$(sqr_name)   sequencer;
        $(prefix_name)_$(cov_name)    coverage;

        uvm_analysis_port #($(prefix_name)_$(tr_name)) item_from_monitor_port;

        function new (string name, uvm_component parent);
            super.new(name, parent);
            //is_active = UVM_ACTIVE;
            //cov_control = $(uppercase(prefix_name))_COV_ENABLE;
            item_from_monitor_port = new("item_from_monitor_port", this);
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if(uvm_config_db#($(prefix_name)_$(cfg_name))::get(.cntxt(this), .inst_name(""), .field_name("cfg"), .value(cfg)))
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Configuration object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) AGENT", "No configuration object was set!")
            uvm_config_db#($(prefix_name)_$(cfg_name))::set(.cntxt(this), .inst_name("*"), .field_name("cfg"), .value(cfg));
            
            if(uvm_config_db#($(prefix_name)_vif)::get(.cntxt(this), .inst_name(""), .field_name("vif"), .value(vif)))
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Virtual interface was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) AGENT", "No interface was set!")
            uvm_config_db#($(prefix_name)_vif)::set(.cntxt(this), .inst_name("*"), .field_name("vif"), .value(vif));
            
            monitor       = $(prefix_name)_$(mon_name)::type_id::create("monitor", this);
            // if (is_active == UVM_ACTIVE) begin
            if (cfg.is_active == UVM_ACTIVE) begin
                sequencer = $(prefix_name)_$(sqr_name)::type_id::create("sequencer", this);
                driver    = $(prefix_name)_$(drv_name)::type_id::create("driver", this);
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Agent is active." , UVM_MEDIUM)
            end else begin
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Agent is not active." , UVM_MEDIUM)
            end

            // if (cov_control == $(uppercase(prefix_name))_COV_ENABLE) begin
            if (cfg.cov_control == $(uppercase(prefix_name))_COV_ENABLE) begin
                coverage = $(prefix_name)_$(cov_name)::type_id::create("coverage", this);
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Coverage is enabled." , UVM_MEDIUM)
            end else begin
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Coverage is disabled." , UVM_MEDIUM)
            end
        endfunction: build_phase

        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);

            //item_from_monitor_port.connect(monitor.item_collected_port);
            monitor.item_collected_port.connect(item_from_monitor_port);
            
            // if (is_active == UVM_ACTIVE) begin
            if (cfg.is_active == UVM_ACTIVE) begin
                driver.seq_item_port.connect(sequencer.seq_item_export);
            end

            // if (cov_control == $(uppercase(prefix_name))_COV_ENABLE) begin
            if (cfg.cov_control == $(uppercase(prefix_name))_COV_ENABLE) begin
                monitor.item_collected_port.connect(coverage.analysis_export);
            end
        endfunction: connect_phase

        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) AGENT", "Simulation initialized", UVM_HIGH)
        endfunction: start_of_simulation_phase

    endclass: $(prefix_name)_$(name)
    """
end

gen_clknrst_agent() = begin 
    prefix_name = "clknrst"
    name = "agent"
    cfg_name = use_short_names ? short_names_dict["config"     ] : "config"
    mon_name = use_short_names ? short_names_dict["monitor"    ] : "monitor"
    drv_name = use_short_names ? short_names_dict["driver"     ] : "driver"
    sqr_name = use_short_names ? short_names_dict["sequencer"  ] : "sequencer"
    cov_name = use_short_names ? short_names_dict["coverage"   ] : "cov"
    tr_name  = use_short_names ? short_names_dict["transaction"] : "transaction"
    return """
    class $(prefix_name)_$(name) extends uvm_agent;

        $(prefix_name)_$(cfg_name) cfg;

        `uvm_component_utils_begin($(prefix_name)_$(name))
            `uvm_field_object(cfg, UVM_ALL_ON)
        `uvm_component_utils_end

        // $(prefix_name)_vif     vif;
        $(prefix_name)_$(mon_name)     monitor;
        $(prefix_name)_$(drv_name)      driver;
        $(prefix_name)_$(sqr_name)   sequencer;
        $(prefix_name)_$(cov_name)    coverage;

        uvm_analysis_port #($(prefix_name)_$(tr_name)) item_from_monitor_port;

        function new (string name, uvm_component parent);
            super.new(name, parent);
            //is_active = UVM_ACTIVE;
            //cov_control = $(uppercase(prefix_name))_COV_ENABLE;
            item_from_monitor_port = new("item_from_monitor_port", this);
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if(uvm_config_db#($(prefix_name)_$(cfg_name))::get(.cntxt(this), .inst_name(""), .field_name("cfg"), .value(cfg)))
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Configuration object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) AGENT", "No configuration object was set!")
            
            uvm_config_db#($(prefix_name)_$(cfg_name))::set(.cntxt(this), .inst_name("*"), .field_name("cfg"), .value(cfg));
            
            monitor       = $(prefix_name)_$(mon_name)::type_id::create("monitor", this);
            // if (is_active == UVM_ACTIVE) begin
            if (cfg.is_active == UVM_ACTIVE) begin
                sequencer = $(prefix_name)_$(sqr_name)::type_id::create("sequencer", this);
                driver    = $(prefix_name)_$(drv_name)::type_id::create("driver", this);
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Agent is active." , UVM_MEDIUM)
            end else begin
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Agent is not active." , UVM_MEDIUM)
            end

            // if (cov_control == $(uppercase(prefix_name))_COV_ENABLE) begin
            if (cfg.cov_control == $(uppercase(prefix_name))_COV_ENABLE) begin
                coverage = $(prefix_name)_$(cov_name)::type_id::create("coverage", this);
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Coverage is enabled." , UVM_MEDIUM)
            end else begin
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Coverage is disabled." , UVM_MEDIUM)
            end
        endfunction: build_phase

        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);

            //item_from_monitor_port.connect(monitor.item_collected_port);
            monitor.item_collected_port.connect(item_from_monitor_port);
            
            // if (is_active == UVM_ACTIVE) begin
            if (cfg.is_active == UVM_ACTIVE) begin
                driver.seq_item_port.connect(sequencer.seq_item_export);
            end

            // if (cov_control == $(uppercase(prefix_name))_COV_ENABLE) begin
            if (cfg.cov_control == $(uppercase(prefix_name))_COV_ENABLE) begin
                monitor.item_collected_port.connect(coverage.analysis_export);
            end
        endfunction: connect_phase

        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) AGENT", "Simulation initialized", UVM_HIGH)
        endfunction: start_of_simulation_phase

    endclass: $(prefix_name)_$(name)
    """
end
    
# ****************************************************************
