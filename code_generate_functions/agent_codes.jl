# ***********************************
# Agent Codes!!!!!
# ***********************************
# No vector is necessary!!!
# ***********************************

gen_agent_base(prefix_name, vec) = """
    class $(prefix_name)_agent extends uvm_agent;

        uvm_active_passive_enum is_active = UVM_ACTIVE;

        `uvm_component_utils_begin($(prefix_name)_agent)
            `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
        `uvm_component_utils_end

        $(prefix_name)_monitor     monitor;
        $(prefix_name)_driver      driver;
        $(prefix_name)_sequencer   sequencer;

        uvm_analysis_port#($(prefix_name)_packet) item_from_monitor_port;

        function new (string name, uvm_component parent);
            super.new(name, parent);
            item_from_monitor_port = new("item_from_monitor_port", this);
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);

            monitor       = $(prefix_name)_monitor::type_id::create("monitor", this);
            if (is_active) begin
                sequencer = $(prefix_name)_sequencer::type_id::create("sequencer", this);
                driver    = $(prefix_name)_driver::type_id::create("driver", this);
            end
        endfunction: build_phase

        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);

            //item_from_monitor_port.connect(monitor.item_collected_port);
            monitor.item_collected_port.connect(item_from_monitor_port);
            
            if (is_active) begin
                driver.seq_item_port.connect(sequencer.seq_item_export);
            end
        endfunction: connect_phase

        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) AGENT", "Simulation initialized", UVM_HIGH)
        endfunction: start_of_simulation_phase

    endclass: $(prefix_name)_agent
    """
# ****************************************************************
