# ***********************************
# Monitor Codes!!!!!
# ***********************************
# Forma do vetor para gerar o monitor:
#  [clock_name , [reset_name , is_negedge?] ]
# 
# Ex:
# vec = ["clock_name", ["reset_name", true]]
# 
# É usado uma parte do vetor da interface: "if_vec[1:2]"
# Esse vetor vem do arquivo VIP_parameters/(VIP name)_parameters.jl
# ***********************************

gen_monitor_base(prefix_name, vec) = """
    class $(prefix_name)_monitor extends uvm_monitor;

        `uvm_component_utils($(prefix_name)_monitor)
    
        $(prefix_name)_vif vif;
        $(prefix_name)_packet pkt;
        int num_pkt_col;

        uvm_analysis_port#($(prefix_name)_packet) item_collected_port;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            num_pkt_col = 0;
            item_collected_port = new("item_collected_port", this);
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            if($(prefix_name)_vif_config::get(this, "", "vif", vif))
                `uvm_info("$(uppercase(prefix_name)) MONITOR", "Virtual interface was successfully set!", UVM_MEDIUM)
            else
                `uvm_error("$(uppercase(prefix_name)) MONITOR", "No interface was set!")        
        endfunction: build_phase

        virtual task run_phase (uvm_phase phase);
            super.run_phase(phase);
            @($((vec[2][2]) ? "negedge" : "posedge") vif.$(vec[2][1]));
            @($((vec[2][2]) ? "posedge" : "negedge") vif.$(vec[2][1]));

            `uvm_info("$(uppercase(prefix_name)) MONITOR", "Reset dropped", UVM_MEDIUM)

            forever begin
                pkt = $(prefix_name)_packet::type_id::create("pkt", this);

                // concurrent blocks for packet collection and transaction recording
                fork
                    // collect packet
                    begin
                        // collect packet from interface
                        vif.collect_packet(pkt);
                    end

                    // Start transaction recording at start of packet (vif.monstart triggered from interface.collect_packet())
                    begin
                        @(posedge vif.monstart) void'(begin_tr(pkt, "$(uppercase(prefix_name))_monitor_Packet"));
                    end
                join

                end_tr(pkt);
                `uvm_info("$(uppercase(prefix_name)) MONITOR", \$sformatf("Packet Collected:\\n%s", pkt.convert2string()), UVM_LOW)
                item_collected_port.write(pkt);
                num_pkt_col++;
            end
        endtask : run_phase

        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) MONITOR", "Simulation initialized", UVM_HIGH)
        endfunction: start_of_simulation_phase

        function void report_phase(uvm_phase phase);
            `uvm_info("$(uppercase(prefix_name)) MONITOR", \$sformatf("Report: $(uppercase(prefix_name)) MONITOR collected %0d packets", num_pkt_col), UVM_LOW)
        endfunction : report_phase

    endclass: $(prefix_name)_monitor
    """
# ****************************************************************
