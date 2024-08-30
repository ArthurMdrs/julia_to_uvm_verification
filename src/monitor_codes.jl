# ***********************************
# Monitor Codes!!!!!
# ***********************************
# Form of the vector to generate the monitor:
#  [clock_name , [reset_name , is_negedge?] ]
# 
# E.g.:
# vec = ["clock_name", ["reset_name", true]]
# 
# A part of the interface's vector is used: "if_vec[1:2]"
# This vector comes from the file UVC_parameters/(UVC name)_parameters.jl
# ***********************************

gen_monitor_base(prefix_name, vec) = begin 
    name = use_short_names ? short_names_dict["monitor"] : "monitor"
    cfg_name = use_short_names ? short_names_dict["config"     ] : "config"
    tr_name  = use_short_names ? short_names_dict["transaction"] : "transaction"
    return """
    class $(prefix_name)_$(name) extends uvm_monitor;

        $(prefix_name)_$(cfg_name) cfg;

        `uvm_component_utils_begin($(prefix_name)_$(name))
            `uvm_field_object(cfg, UVM_ALL_ON)
        `uvm_component_utils_end
    
        $(prefix_name)_vif vif;
        $(prefix_name)_$(tr_name) tr;
        int num_tr_col;

        uvm_analysis_port #($(prefix_name)_$(tr_name)) item_collected_port;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            num_tr_col = 0;
            item_collected_port = new("item_collected_port", this);
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if(uvm_config_db#($(prefix_name)_vif)::get(.cntxt(this), .inst_name(""), .field_name("vif"), .value(vif)))
                `uvm_info("$(uppercase(prefix_name)) MONITOR", "Virtual interface was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) MONITOR", "No interface was set!")
                
            if(uvm_config_db#($(prefix_name)_$(cfg_name))::get(.cntxt(this), .inst_name(""), .field_name("cfg"), .value(cfg)))
                `uvm_info("$(uppercase(prefix_name)) MONITOR", "Configuration object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) MONITOR", "No configuration object was set!")
        endfunction: build_phase

        virtual task run_phase (uvm_phase phase);
            super.run_phase(phase);
            @($((vec[2][2]) ? "negedge" : "posedge") vif.$(vec[2][1]));
            @($((vec[2][2]) ? "posedge" : "negedge") vif.$(vec[2][1]));

            `uvm_info("$(uppercase(prefix_name)) MONITOR", "Reset dropped", UVM_MEDIUM)

            forever begin
                tr = $(prefix_name)_$(tr_name)::type_id::create("tr", this);

                // concurrent blocks for transaction collection and transaction recording
                fork
                    // collect transaction
                    begin
                        // collect transaction from interface
                        vif.collect_tr(tr);
                    end

                    // Start transaction recording at start of transaction (vif.monstart triggered from interface.collect_tr())
                    begin
                        @(posedge vif.monstart) void'(begin_tr(tr, "$(uppercase(prefix_name))_MONITOR_TR"));
                    end
                join

                end_tr(tr);
                `uvm_info("$(uppercase(prefix_name)) MONITOR", \$sformatf("Transaction Collected:\\n%s", tr.convert2string()), UVM_LOW)
                item_collected_port.write(tr);
                num_tr_col++;
            end
        endtask : run_phase

        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) MONITOR", "Simulation initialized", UVM_HIGH)
        endfunction: start_of_simulation_phase

        function void report_phase(uvm_phase phase);
            `uvm_info("$(uppercase(prefix_name)) MONITOR", \$sformatf("Report: $(uppercase(prefix_name)) MONITOR collected %0d transactions", num_tr_col), UVM_LOW)
        endfunction : report_phase

    endclass: $(prefix_name)_$(name)
    """
    end
# ****************************************************************
