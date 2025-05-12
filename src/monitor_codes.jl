# ***********************************
# Monitor Codes
# ***********************************
# Creates an monitor class
# ***********************************

get_normal_mon_funcs(prefix_name) = begin
    tr_name  = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = get_uvc_cfg_fld(prefix_name, :uvc_has_params) ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    verb_dict = get_uvc_cfg_fld(prefix_name, :verbosities)
    if reset_mechanism == run_phase_reset
        reset_name = get_uvc_cfg_fld(prefix_name, :reset_name)
        rst_is_negedge_sensitive = get_uvc_cfg_fld(prefix_name, :rst_is_negedge_sensitive)
        my_str =  """
            task run_phase (uvm_phase phase);
                super.run_phase(phase);
                @($((rst_is_negedge_sensitive) ? "negedge" : "posedge") vif.$(reset_name));
                @($((rst_is_negedge_sensitive) ? "posedge" : "negedge") vif.$(reset_name));
                
                `uvm_info("$(uppercase(prefix_name)) MONITOR", "Reset dropped", $(verb_dict["reset_dropped"]))
                
                collect();
            endtask : run_phase
            
        """
    elseif reset_mechanism == reset_phase_reset
        my_str =  """
            task reset_phase (uvm_phase phase);
                `uvm_info("$(uppercase(prefix_name)) MONITOR", "Entering reset phase.", $(verb_dict["enter_reset_phase"]))
                mon_tr = null;
                collect();
            endtask: reset_phase
            
            task main_phase (uvm_phase phase);
                super.main_phase(phase);
                `uvm_info("$(uppercase(prefix_name)) MONITOR", "Entering main phase", $(verb_dict["enter_main_phase"]))
                
                end_tr(mon_tr);
                
                collect();
            endtask : main_phase
            
        """
    end
    my_str *= """
        task collect ();
            forever begin
                mon_tr = $(tr_type)::type_id::create("mon_tr", this);
                
                void'(begin_tr(mon_tr, "$(uppercase(prefix_name))_MONITOR_TR"));
                vif.collect_tr(mon_tr);
                end_tr(mon_tr);
                
                `uvm_info("$(uppercase(prefix_name)) MONITOR", \$sformatf("Transaction Collected:%s", mon_tr.convert2string()), $(verb_dict["collect_tr"]))
                item_collected_port.write(mon_tr);
                num_tr_col++;
            end
        endtask : collect
        
    """
    return my_str
end
get_clknrst_mon_funcs(prefix_name) = begin
    tr_name  = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = get_uvc_cfg_fld(prefix_name, :uvc_has_params) ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
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
    tr_type = get_uvc_cfg_fld(prefix_name, :uvc_has_params) ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    verb_dict = get_uvc_cfg_fld(prefix_name, :verbosities)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    gen_lines_tdefs_w_param_uvc(name, tabs) = gen_lines_tdefs_w_param(params_prefix, name, tabs)
    my_str = """
    class $(prefix_name)_$(mon_name) $(get_param_declaration_w_seq_item(params_prefix, "    "))extends uvm_monitor;
        
    """
    
    if get_uvc_cfg_fld(prefix_name, :uvc_has_params)
        my_str *= """
            `uvm_component_param_utils($(prefix_name)_$(mon_name) $(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(prefix_name)_$(mon_name))
        """
    end
    
    my_str *= """
        
    $( gen_lines_tdefs_w_param_uvc("$(prefix_name)_$(cfg_name)", "    ")[1:end-1] )
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
            `uvm_info("$(uppercase(prefix_name)) MONITOR", "Simulation initialized", $(verb_dict["sim_init"]))
        endfunction : start_of_simulation_phase
        
        function void report_phase(uvm_phase phase);
            `uvm_info("$(uppercase(prefix_name)) MONITOR", \$sformatf("Report: $(uppercase(prefix_name)) MONITOR collected %0d transactions", num_tr_col), $(verb_dict["monitor_report"]))
        endfunction : report_phase
        
    endclass : $(prefix_name)_$(mon_name)
    """
    return my_str
end

gen_monitor_base(prefix_name) = gen_monitor(prefix_name, normal::uvc_class_type)
gen_clknrst_monitor(prefix_name) = gen_monitor(prefix_name, clknrst::uvc_class_type)

# ****************************************************************
