# ***********************************
# Agent Codes!!!!!
# ***********************************
# No vector is necessary!!!
# ***********************************

gen_agent_base(prefix_name, vec) = """
    typedef enum bit {COV_ENABLE, COV_DISABLE} cover_e;

    class $(prefix_name)_agent extends uvm_agent;

        uvm_active_passive_enum is_active = UVM_ACTIVE;
        cover_e cov_control = COV_ENABLE;

        `uvm_component_utils_begin($(prefix_name)_agent)
            `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
            `uvm_field_enum(cover_e, cov_control, UVM_ALL_ON)
        `uvm_component_utils_end

        $(prefix_name)_monitor     monitor;
        $(prefix_name)_driver      driver;
        $(prefix_name)_sequencer   sequencer;
        $(prefix_name)_coverage    coverage;

        uvm_analysis_port #($(prefix_name)_packet) item_from_monitor_port;

        function new (string name, uvm_component parent);
            super.new(name, parent);
            item_from_monitor_port = new("item_from_monitor_port", this);
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);

            monitor       = $(prefix_name)_monitor::type_id::create("monitor", this);
            if (is_active == UVM_ACTIVE) begin
                sequencer = $(prefix_name)_sequencer::type_id::create("sequencer", this);
                driver    = $(prefix_name)_driver::type_id::create("driver", this);
            end

            if (cov_control == COV_ENABLE) begin
                coverage = $(prefix_name)_coverage::type_id::create("coverage", this);
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Coverage is enabled." , UVM_LOW) 
            end else begin
                `uvm_info("$(uppercase(prefix_name)) AGENT", "Coverage is disabled." , UVM_LOW)
            end
        endfunction: build_phase

        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);

            //item_from_monitor_port.connect(monitor.item_collected_port);
            monitor.item_collected_port.connect(item_from_monitor_port);
            
            if (is_active == UVM_ACTIVE) begin
                driver.seq_item_port.connect(sequencer.seq_item_export);
            end

            if (cov_control == COV_ENABLE) begin
                monitor.item_collected_port.connect(coverage.analysis_export);
            end
        endfunction: connect_phase

        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) AGENT", "Simulation initialized", UVM_HIGH)
        endfunction: start_of_simulation_phase

    endclass: $(prefix_name)_agent
    """
# ****************************************************************
