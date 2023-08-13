class some_vip_monitor extends uvm_monitor;

    `uvm_component_utils(some_vip_monitor)

    some_vip_vif vif;
    some_vip_packet pkt;
    int num_pkt_col;

    uvm_analysis_port#(some_vip_packet) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        num_pkt_col = 0;
        item_collected_port = new("item_collected_port", this);
    endfunction: new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        if(some_vip_vif_config::get(this, "", "vif", vif))
            `uvm_info("SOME_VIP MONITOR", "Virtual interface was successfully got!", UVM_MEDIUM)
        else
            `uvm_error("SOME_VIP MONITOR", "No interface was set!")        
    endfunction: build_phase

    virtual task run_phase (uvm_phase phase);
        super.run_phase(phase);
        @(negedge vif.rst_n);
        @(posedge vif.rst_n);

        `uvm_info("SOME_VIP MONITOR", "Reset dropped", UVM_MEDIUM)

        forever begin
            pkt = some_vip_packet::type_id::create("pkt", this);

            // concurrent blocks for packet collection and transaction recording
            fork
                // collect packet
                begin
                    // collect packet from interface
                    vif.collect_packet(pkt);
                end

                // Start transaction recording at start of packet (vif.monstart triggered from interface.collect_packet())
                begin
                    @(posedge vif.monstart) void'(begin_tr(pkt, "SOME_VIP_monitor_Packet"));
                end
            join

            end_tr(pkt);
            `uvm_info("SOME_VIP MONITOR", $sformatf("Packet Collected:\n%s", pkt.convert2string()), UVM_LOW)
            item_collected_port.write(pkt);
            num_pkt_col++;
        end
    endtask : run_phase

    function void start_of_simulation_phase (uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info("SOME_VIP MONITOR", "Simulation initialized", UVM_HIGH)
    endfunction: start_of_simulation_phase

    function void report_phase(uvm_phase phase);
        `uvm_info("SOME_VIP MONITOR", $sformatf("Report: SOME_VIP MONITOR collected %0d packets", num_pkt_col), UVM_LOW)
    endfunction : report_phase

endclass: some_vip_monitor
