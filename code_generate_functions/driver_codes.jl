# *******************
# Driver Codes!!!!!
# ***********************************
# Form of the vector to generate the driver:
#  [clock_name , [reset_name , is_negedge?] ]
# 
# E.g.:
# vec = ["clock_name", ["reset_name", true]]
# 
# A part of the interface's vector is used: "if_vec[1:2]"
# This vector comes from the file VIP_parameters/(VIP name)_parameters.jl
# ***********************************

gen_driver_base(prefix_name, vec) = """
    class $(prefix_name)_driver extends uvm_driver #($(prefix_name)_packet);

        `uvm_component_utils($(prefix_name)_driver)
    
        $(prefix_name)_vif vif;
        int num_sent;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            num_sent = 0;
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            if($(prefix_name)_vif_config::get(this, "", "vif", vif))
                `uvm_info("$(uppercase(prefix_name)) DRIVER", "Virtual interface was successfully set!", UVM_MEDIUM)
            else
                `uvm_error("$(uppercase(prefix_name)) DRIVER", "No interface was set!")
        endfunction: build_phase

        virtual task run_phase (uvm_phase phase);
            super.run_phase(phase);
            fork
                get_and_drive();
                reset_signals();
            join
        endtask: run_phase

        task get_and_drive();
            @($((vec[2][2]) ? "negedge" : "posedge") vif.$(vec[2][1]));
            @($((vec[2][2]) ? "posedge" : "negedge") vif.$(vec[2][1]));

            `uvm_info("$(uppercase(prefix_name)) DRIVER", "Reset dropped", UVM_MEDIUM)

            forever begin
                // Get new item from the sequencer
                seq_item_port.get_next_item(req);
                `uvm_info("$(uppercase(prefix_name)) DRIVER", \$sformatf("Packet to send is:%s", req.convert2string()), UVM_MEDIUM)

                // concurrent blocks for packet driving and transaction recording
                fork
                    // send packet
                    begin
                        // send packet via interface
                        vif.send_to_dut(req);
                    end

                    // Start transaction recording at start of packet (vif.drvstart triggered from interface.send_to_dut())
                    begin
                        @(posedge vif.drvstart) void'(begin_tr(req, "$(uppercase(prefix_name))_DRIVER_Packet"));
                    end
                join

                end_tr(req);
                num_sent++;
                seq_item_port.item_done();
            end
        endtask : get_and_drive

        task reset_signals();
            forever begin
                vif.$(prefix_name)_reset();
                `uvm_info("$(uppercase(prefix_name)) DRIVER", "Reset done", UVM_NONE)
            end
        endtask : reset_signals

        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) DRIVER", "Simulation initialized", UVM_HIGH)
        endfunction: start_of_simulation_phase

        function void report_phase(uvm_phase phase);
            `uvm_info("$(uppercase(prefix_name)) DRIVER", \$sformatf("Report: $(uppercase(prefix_name)) DRIVER sent %0d packets", num_sent), UVM_LOW)
        endfunction : report_phase

    endclass: $(prefix_name)_driver
    """
# ****************************************************************
