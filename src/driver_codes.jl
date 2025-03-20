# *******************
# Driver Codes!!!!!
# ***********************************
# Creates a driver class
# ***********************************

get_normal_drv_funcs(prefix_name) = begin
    if reset_mechanism == run_phase_reset
        reset_name = get_uvc_cfg_fld(prefix_name, :reset_name)
        rst_is_negedge_sensitive = get_uvc_cfg_fld(prefix_name, :rst_is_negedge_sensitive)
        my_str =  """
            task run_phase (uvm_phase phase);
                super.run_phase(phase);
                fork
                    begin
                        @($((rst_is_negedge_sensitive) ? "negedge" : "posedge") vif.$(reset_name));
                        @($((rst_is_negedge_sensitive) ? "posedge" : "negedge") vif.$(reset_name));
                        
                        `uvm_info("$(uppercase(prefix_name)) DRIVER", "Reset dropped", UVM_MEDIUM)
                        
                        get_and_drive();
                    end
                    reset_signals();
                join
            endtask : run_phase
            
            task reset_signals();
                forever begin
                    vif.$(prefix_name)_reset();
                    `uvm_info("$(uppercase(prefix_name)) DRIVER", "Detected reset", UVM_LOW)
                end
            endtask : reset_signals
            
        """
    elseif reset_mechanism == reset_phase_reset
        my_str =  """
            task reset_phase (uvm_phase phase);
                `uvm_info("$(uppercase(prefix_name)) DRIVER", "Entering reset phase.", UVM_MEDIUM)
                vif.$(prefix_name)_reset();
                get_and_drive();
            endtask: reset_phase
            
            task main_phase (uvm_phase phase);
                super.main_phase(phase);
                
                `uvm_info("$(uppercase(prefix_name)) DRIVER", "Entering main phase", UVM_MEDIUM)
                
                get_and_drive();
            endtask : main_phase
            
        """
    end
    my_str *= """
        task get_and_drive();
            forever begin
                seq_item_port.get_next_item(req);
                `uvm_info("$(uppercase(prefix_name)) DRIVER", \$sformatf("Sending transaction:%s", req.convert2string()), UVM_HIGH)
                
                void'(begin_tr(req, "$(uppercase(prefix_name))_DRIVER_TR"));
                vif.send_to_dut(req);
                end_tr(req);
                
                num_sent++;
                seq_item_port.item_done();
            end
        endtask : get_and_drive
        
    """
    return my_str
end
get_clknrst_drv_funcs(prefix_name) = begin
    tr_name  = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = has_parameters ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    my_str =  """
        task run_phase (uvm_phase phase);
            super.run_phase(phase);
            
            case ($(config_inst_convention).initial_rst_val)
                $(uppercase(prefix_name))_INITIAL_VALUE_0: vif.set_rst_val(1'b0);
                $(uppercase(prefix_name))_INITIAL_VALUE_1: vif.set_rst_val(1'b1);
                $(uppercase(prefix_name))_INITIAL_VALUE_X: vif.set_rst_val(1'bx);
                default: `uvm_fatal("$(uppercase(prefix_name)) DRIVER", \$sformatf("Illegal initial value for reset: %s", $(config_inst_convention).initial_rst_val))
            endcase
            
            forever begin
                seq_item_port.get_next_item(req);
                void'(begin_tr(req, "$(uppercase(prefix_name))_DRIVER_TR"));
                drive_req(req);
                end_tr(req);
                num_sent++;
                seq_item_port.item_done();
            end
        endtask : run_phase
        
        task drive_req ($(tr_type) req);
            case (req.action)
                $(uppercase(prefix_name))_ACTION_START_CLK: begin
                    if (vif.clk_active) begin
                        `uvm_warning("$(uppercase(prefix_name)) DRIVER", \$sformatf("Attempting to start clock generation while it is already active. Ignoring req:\\n%s", req.sprint()))
                    end
                    else begin
                        if ($(config_inst_convention).set_clk_period_from_config) begin
                            vif.set_period($(config_inst_convention).clk_period * 1ps);
                        end else if (req.clk_period != 0) begin
                            vif.set_period(req.clk_period * 1ps);
                        end
                        case (req.initial_clk_val)
                            $(uppercase(prefix_name))_INITIAL_VALUE_0: vif.set_clk_val(1'b0);
                            $(uppercase(prefix_name))_INITIAL_VALUE_1: vif.set_clk_val(1'b1);
                            $(uppercase(prefix_name))_INITIAL_VALUE_X: vif.set_clk_val(1'bx);
                        endcase
                        vif.start_clk();
                        //vif.wait_clk_negedge();
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
                        //vif.wait_clk_negedge();
                    end
                end
                
                $(uppercase(prefix_name))_ACTION_ASSERT_RESET: begin
                    vif.assert_rst(req.rst_assert_duration);
                end
            endcase
        endtask : drive_req
        
    """
    return my_str
end

gen_driver(prefix_name, type::uvc_class_type) = begin
    drv_name = get_uvc_cfg_fld(prefix_name, :class_names)["driver"     ]
    cfg_name = get_uvc_cfg_fld(prefix_name, :class_names)["config"     ]
    tr_name  = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = has_parameters ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    my_str = """
    class $(prefix_name)_$(drv_name) $(get_param_declaration_w_seq_item(params_vec, dut_name, "    "))extends uvm_driver #($(tr_type));
        
    """
    
    if has_parameters
        my_str *= """
            `uvm_component_param_utils($(prefix_name)_$(drv_name) $(get_param_conn_w_seq_item2(dut_name, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(prefix_name)_$(drv_name))
        """
    end
    
    my_str *= """
        
    $( gen_lines_tdefs_w_param("$(prefix_name)_$(cfg_name)", "    ")[1:end-1] )
    $( gen_line_vif_typedef(prefix_name, "    ")[1:end-1] )
        
        $(prefix_name)_$(cfg_name)_t $(config_inst_convention);
        
        $(prefix_name)_vif_t vif;
        
        int num_sent;
        
        function new(string name, uvm_component parent);
            super.new(name, parent);
            num_sent = 0;
        endfunction : new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if ($(config_inst_convention) == null)
                `uvm_fatal("$(uppercase(prefix_name)) DRIVER", "No configuration object was set!")
    """
    if get_uvc_cfg_fld(prefix_name, :vif_in_config) == false
        my_str *= """
                
        $( gen_vif_config_db_component(prefix_name, "        ", "DRIVER")[1:end-1] )
        """
    else
        my_str *= """
                
                if ($(config_inst_convention).vif == null)
                    `uvm_fatal("$(uppercase(prefix_name)) DRIVER", "No interface was set!")
                vif = $(config_inst_convention).vif;
        """
    end
    my_str *= """
        endfunction : build_phase
        
    """
    
    if type == normal::uvc_class_type
        my_str *= get_normal_drv_funcs(prefix_name)
    elseif type == clknrst::uvc_class_type
        my_str *= get_clknrst_drv_funcs(prefix_name)
    end
    
    my_str *= """
        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) DRIVER", "Simulation initialized", UVM_HIGH)
        endfunction : start_of_simulation_phase
        
        function void report_phase(uvm_phase phase);
            `uvm_info("$(uppercase(prefix_name)) DRIVER", \$sformatf("Report: $(uppercase(prefix_name)) DRIVER sent %0d transactions", num_sent), UVM_NONE)
        endfunction : report_phase
        
    endclass : $(prefix_name)_$(drv_name)
    """
    return my_str
end

gen_driver_base(prefix_name) = gen_driver(prefix_name, normal::uvc_class_type)
gen_clknrst_driver(prefix_name) = gen_driver(prefix_name, clknrst::uvc_class_type)

# ****************************************************************
