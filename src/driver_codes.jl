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
# This vector comes from the file UVC_parameters/(UVC name)_parameters.jl
# ***********************************

gen_driver_base(prefix_name, vec) = begin
    name = use_short_names ? short_names_dict["driver"] : "driver"
    cfg_name = use_short_names ? short_names_dict["config"     ] : "config"
    tr_name  = use_short_names ? short_names_dict["transaction"] : "transaction"
    return """
    class $(prefix_name)_$(name) extends uvm_driver #($(prefix_name)_$(tr_name));

        $(prefix_name)_$(cfg_name) cfg;

        `uvm_component_utils_begin($(prefix_name)_$(name))
            `uvm_field_object(cfg, UVM_ALL_ON)
        `uvm_component_utils_end
    
        $(prefix_name)_vif vif;
        int num_sent;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            num_sent = 0;
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
                
            if(uvm_config_db#($(prefix_name)_$(cfg_name))::get(.cntxt(this), .inst_name(""), .field_name("cfg"), .value(cfg)))
                `uvm_info("$(uppercase(prefix_name)) DRIVER", "Configuration object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) DRIVER", "No configuration object was set!")
            
            if(uvm_config_db#($(prefix_name)_vif)::get(.cntxt(this), .inst_name(""), .field_name("vif"), .value(vif)))
                `uvm_info("$(uppercase(prefix_name)) DRIVER", "Virtual interface was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) DRIVER", "No interface was set!")
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
                `uvm_info("$(uppercase(prefix_name)) DRIVER", \$sformatf("Sending transaction:%s", req.convert2string()), UVM_MEDIUM)

                // concurrent blocks for transaction driving and transaction recording
                fork
                    // send transaction
                    begin
                        // send transaction via interface
                        vif.send_to_dut(req);
                    end

                    // Start transaction recording at start of transaction (vif.drvstart triggered from interface.send_to_dut())
                    begin
                        @(posedge vif.drvstart) void'(begin_tr(req, "$(uppercase(prefix_name))_DRIVER_TR"));
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
                `uvm_info("$(uppercase(prefix_name)) DRIVER", "Detected reset", UVM_LOW)
            end
        endtask : reset_signals

        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) DRIVER", "Simulation initialized", UVM_HIGH)
        endfunction: start_of_simulation_phase

        function void report_phase(uvm_phase phase);
            `uvm_info("$(uppercase(prefix_name)) DRIVER", \$sformatf("Report: $(uppercase(prefix_name)) DRIVER sent %0d transactions", num_sent), UVM_NONE)
        endfunction : report_phase

    endclass: $(prefix_name)_$(name)
    """
end

gen_clknrst_driver() = begin
    prefix_name = "clknrst"
    name = use_short_names ? short_names_dict["driver"] : "driver"
    cfg_name = use_short_names ? short_names_dict["config"     ] : "config"
    tr_name  = use_short_names ? short_names_dict["transaction"] : "transaction"
    return """
    class $(prefix_name)_$(name) extends uvm_driver #($(prefix_name)_$(tr_name));

        $(prefix_name)_$(cfg_name) cfg;

        `uvm_component_utils_begin($(prefix_name)_$(name))
            `uvm_field_object(cfg, UVM_ALL_ON)
        `uvm_component_utils_end
    
        $(prefix_name)_vif vif;
        int num_sent;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            num_sent = 0;
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
                
            if(uvm_config_db#($(prefix_name)_$(cfg_name))::get(.cntxt(this), .inst_name(""), .field_name("cfg"), .value(cfg)))
                `uvm_info("$(uppercase(prefix_name)) DRIVER", "Configuration object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) DRIVER", "No configuration object was set!")
            
            if(uvm_config_db#($(prefix_name)_vif)::get(.cntxt(this), .inst_name(""), .field_name("vif"), .value(vif)))
                `uvm_info("$(uppercase(prefix_name)) DRIVER", "Virtual interface was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) DRIVER", "No interface was set!")
        endfunction: build_phase

        virtual task run_phase (uvm_phase phase);
            super.run_phase(phase);
            
            case (cfg.initial_rst_val)
                $(uppercase(prefix_name))_INITIAL_VALUE_0: vif.set_rst_val(1'b0);
                $(uppercase(prefix_name))_INITIAL_VALUE_1: vif.set_rst_val(1'b1);
                $(uppercase(prefix_name))_INITIAL_VALUE_X: vif.set_rst_val(1'bx);
                default: `uvm_fatal("$(uppercase(prefix_name)) DRIVER", \$sformatf("Illegal initial value for reset: %s", cfg.initial_rst_val))
            endcase

            forever begin
                seq_item_port.get_next_item(req);
                void'(begin_tr(req, "$(uppercase(prefix_name))_DRIVER_TR"));
                drive_req (req);
                end_tr(req);
                num_sent++;
                seq_item_port.item_done();
            end
        endtask: run_phase



        task drive_req($(prefix_name)_$(tr_name) req);
            case (req.action)
                $(uppercase(prefix_name))_ACTION_START_CLK: begin
                    if (vif.clk_active) begin
                        `uvm_warning("$(uppercase(prefix_name)) DRIVER", \$sformatf("Attempting to start clock generation while it is already active. Ignoring req:\\n%s", req.sprint()))
                    end
                    else begin
                        if (req.clk_period != 0) begin
                            vif.set_period(req.clk_period * 1ps);
                        end
                        case (req.initial_clk_val)
                            $(uppercase(prefix_name))_INITIAL_VALUE_0: vif.set_clk_val(1'b0);
                            $(uppercase(prefix_name))_INITIAL_VALUE_1: vif.set_clk_val(1'b1);
                            $(uppercase(prefix_name))_INITIAL_VALUE_X: vif.set_clk_val(1'bx);
                        endcase
                        vif.start_clk();
                    end
                end
                
                $(uppercase(prefix_name))_ACTION_STOP_CLK: begin
                    if (!vif.clk_active) begin
                        `uvm_warning("$(uppercase(prefix_name)) DRIVER", \$sformatf("Attempting to stop clock generation while it is already inactive. Ignoring req:\\n%s", req.sprint()))
                    end
                    else begin
                        // wait (vif.clk == 1'b0);
                        vif.stop_clk();
                    end
                end
            
                $(uppercase(prefix_name))_ACTION_RESTART_CLK: begin
                    if (vif.clk_active) begin
                        `uvm_warning("$(uppercase(prefix_name)) DRIVER", \$sformatf("Attempting to restart clock generation while it is already active. Ignoring req:\\n%s", req.sprint()))
                    end
                    else begin
                        vif.start_clk();
                    end
                end
            
                $(uppercase(prefix_name))_ACTION_ASSERT_RESET: begin
                    vif.assert_rst(req.rst_assert_duration);
                end
            endcase
        endtask : drive_req

        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) DRIVER", "Simulation initialized", UVM_HIGH)
        endfunction: start_of_simulation_phase

        function void report_phase(uvm_phase phase);
            `uvm_info("$(uppercase(prefix_name)) DRIVER", \$sformatf("Report: $(uppercase(prefix_name)) DRIVER sent %0d transactions", num_sent), UVM_LOW)
        endfunction : report_phase

    endclass: $(prefix_name)_$(name)
    """
end

# ****************************************************************
