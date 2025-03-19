# ***********************************
# Monitor Codes
# ***********************************
# Creates an monitor class
# The gen_monitor_base function needs a vector as an argument
# Form of the vector to generate the monitor:
#  [clock_name , [reset_name , is_negedge?] ]
# 
# E.g.:
# vec = ["clock_name", ["reset_name", true]]
# 
# A part of the interface's vector is used: "if_vec[1:2]"
# This vector comes from the file UVC_parameters/(UVC name)_parameters.jl
# ***********************************

get_normal_mon_funcs(prefix_name) = begin
    tr_name  = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = has_parameters ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    my_str =  """
        task reset_phase (uvm_phase phase);
            `uvm_info("$(uppercase(prefix_name)) MONITOR", "Entering reset phase.", UVM_MEDIUM)
            mon_tr = null;
            collect();
        endtask: reset_phase
        
        task main_phase (uvm_phase phase);
            super.main_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) MONITOR", "Entering main phase", UVM_MEDIUM)
            
            end_tr(mon_tr);
            
            collect();
        endtask : main_phase
        
        task collect ();
            forever begin
                mon_tr = seq_item_t::type_id::create("mon_tr", this);
                
                void'(begin_tr(mon_tr, "$(uppercase(prefix_name))_MONITOR_TR"));
                vif.collect_tr(mon_tr);
                end_tr(mon_tr);
                
                `uvm_info("$(uppercase(prefix_name)) MONITOR", \$sformatf("Transaction Collected:%s", mon_tr.convert2string()), UVM_MEDIUM)
                item_collected_port.write(mon_tr);
                num_tr_col++;
            end
        endtask : collect
        
    """
    return my_str
end
get_clknrst_mon_funcs(prefix_name) = begin
    tr_name  = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = has_parameters ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    my_str =  """
        task run_phase (uvm_phase phase);
            super.run_phase(phase);
            
            // What should we do here?
            forever begin
                // tr = $(tr_type)::type_id::create("tr", this);
                // void'(begin_tr(tr, "$(uppercase(prefix_name))_MONITOR_TR"));
                
                vif.wait_clk_posedge();
                
                // end_tr(tr);
                // item_collected_port.write(tr);
                // num_tr_col++;
            end
        endtask : run_phase
        
    """
    return my_str
end

gen_monitor(prefix_name, type::uvc_class_type) = begin 
    mon_name = get_uvc_cfg_fld(prefix_name, :class_names)["monitor"    ]
    cfg_name = get_uvc_cfg_fld(prefix_name, :class_names)["config"     ]
    tr_name  = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = has_parameters ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    reset_name = get_uvc_cfg_fld(prefix_name, :reset_name)
    rst_is_negedge_sensitive = get_uvc_cfg_fld(prefix_name, :rst_is_negedge_sensitive)
    my_str = """
    class $(prefix_name)_$(mon_name) $(get_param_declaration_w_seq_item(params_vec, dut_name, "    "))extends uvm_monitor;
        
    """
    
    if has_parameters
        my_str *= """
            `uvm_component_param_utils($(prefix_name)_$(mon_name) $(get_param_conn_w_seq_item2(dut_name, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(prefix_name)_$(mon_name))
        """
    end
    
    my_str *= """
        
    $( gen_lines_tdefs_w_param("$(prefix_name)_$(cfg_name)", "    ")[1:end-1] )
    $( gen_line_vif_typedef(prefix_name, "    ")[1:end-1] )
        
        $(prefix_name)_$(cfg_name)_t $(config_inst_convention);
        
        $(prefix_name)_vif_t vif;
        $(tr_type) mon_tr;
        int num_tr_col;
        
        uvm_analysis_port #($(tr_type)) item_collected_port;
        
        function new(string name, uvm_component parent);
            super.new(name, parent);
            num_tr_col = 0;
            item_collected_port = new("item_collected_port", this);
        endfunction : new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if ($(config_inst_convention) == null)
                `uvm_fatal("$(uppercase(prefix_name)) MONITOR", "No configuration object was set!")
    """
    if get_uvc_cfg_fld(prefix_name, :vif_in_config) == false
        my_str *= """
                
        $( gen_vif_config_db_component(prefix_name, "        ", "MONITOR")[1:end-1] )
        """
    else
        my_str *= """
                
                if ($(config_inst_convention).vif == null)
                    `uvm_fatal("$(uppercase(prefix_name)) MONITOR", "No interface was set!")
                vif = $(config_inst_convention).vif;
        """
    end
    my_str *= """
        endfunction : build_phase
        
    """
    
    if type == normal::uvc_class_type
        my_str *= get_normal_mon_funcs(prefix_name)
    elseif type == clknrst::uvc_class_type
        my_str *= get_clknrst_mon_funcs(prefix_name)
    end
    
    my_str *= """
        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) MONITOR", "Simulation initialized", UVM_HIGH)
        endfunction : start_of_simulation_phase
        
        function void report_phase(uvm_phase phase);
            `uvm_info("$(uppercase(prefix_name)) MONITOR", \$sformatf("Report: $(uppercase(prefix_name)) MONITOR collected %0d transactions", num_tr_col), UVM_NONE)
        endfunction : report_phase
        
    endclass : $(prefix_name)_$(mon_name)
    """
    return my_str
end

gen_monitor_base(prefix_name) = gen_monitor(prefix_name, normal::uvc_class_type)
gen_clknrst_monitor(prefix_name) = gen_monitor(prefix_name, clknrst::uvc_class_type)

# ****************************************************************
