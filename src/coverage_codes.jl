# ***********************************
# Coverage Codes
# ***********************************
# Creates a coverage class
# ***********************************

gen_line_coverpoint(vec::tr_field_t, tabs) = begin
    my_str = ""
    aux = false
    aux = aux || (vec.type in packed_types && size(vec.size)[1] == 1)
    aux = aux || (vec.type in integer_types && size(vec.size)[1] == 1 && vec.size[1] == 1)
    if aux
        my_str = """
        $(tabs)$(vec.field_name)_cp: coverpoint cov_transaction.$(vec.field_name) {
        $(tabs)    option.at_least = 2;
        $(tabs)    bins $(vec.field_name)_bin [] = {[0:\$]};
        $(tabs)}
        """
    end
    return my_str
end
gen_line_report_coverage(vec::tr_field_t, tabs, prefix_name) = begin
    my_str = ""
    aux = false
    aux = aux || (vec.type in packed_types && size(vec.size)[1] == 1)
    aux = aux || (vec.type in integer_types && size(vec.size)[1] == 1 && vec.size[1] == 1)
    if aux
        my_str = """
        $(tabs)\$sformat(msg, "%s \\t\\t- $(vec.field_name)_cp: %.2f%% \\n", msg, $(prefix_name)_covergroup.$(vec.field_name)_cp.get_inst_coverage());
        """
    end
    return my_str
end

gen_coverage_base(prefix_name) = begin
    cov_name = get_uvc_cfg_fld(prefix_name, :class_names)["coverage"   ]
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "agent_" * get_uvc_cfg_fld(prefix_name, :class_names)["config"]
    else
        cfg_name = get_uvc_cfg_fld(prefix_name, :class_names)["config" ]
    end
    tr_name  = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    tr_type = get_uvc_cfg_fld(prefix_name, :uvc_has_params) ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    vec = get_uvc_cfg_fld(prefix_name, :tr_props_vec)
    verb_dict = get_uvc_cfg_fld(prefix_name, :verbosities)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    gen_lines_tdefs_w_param_uvc(name, tabs) = gen_lines_tdefs_w_param(params_prefix, name, tabs)
    my_str = """
    class $(prefix_name)_$(cov_name) $(get_param_declaration_w_seq_item(params_prefix, "    "))extends uvm_subscriber #($(tr_type));
        
    """

    if get_uvc_cfg_fld(prefix_name, :uvc_has_params)
        my_str *= """
            `uvm_component_param_utils($(prefix_name)_$(cov_name) $(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(prefix_name)_$(cov_name))
        """
    end
    
    my_str *= """
        
    $( gen_lines_tdefs_w_param_uvc("$(prefix_name)_$(cfg_name)", "    ")[1:end-1] )
        
        $(prefix_name)_$(cfg_name)_t m_$(cfg_name);
        
        real coverage_value;
        $(tr_type) cov_transaction;
        
        covergroup $(prefix_name)_covergroup;
            option.per_instance = 1;
            option.name = {get_full_name(), ".", "covergroup"};
            // option.at_least = 3;
            // option.auto_bin_max = 256;
            // option.cross_auto_bin_max = 256;
    $( gen_long_str(vec, "        ", gen_line_coverpoint)[1:end-1] )
        endgroup : $(prefix_name)_covergroup
        
        function new (string name, uvm_component parent);
            super.new(name, parent);
            $(prefix_name)_covergroup = new();
        endfunction : new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            if (m_$(cfg_name) == null)
                `uvm_fatal("$(uppercase(prefix_name)) COVERAGE", "No configuration object was set!")
        endfunction : build_phase
        
        function void report_phase (uvm_phase phase);
            string msg;
            super.report_phase(phase);
            
            msg = "";
            \$sformat(msg, "%s \\n------------------------------------------------------------------------------------------------------------\\n", msg);
            \$sformat(msg, "%s FUNCTIONAL COVERAGE SUMMARY \\n", msg);
            \$sformat(msg, "%s \\t- Overview: %.2f%% \\n", msg, $(prefix_name)_covergroup.get_inst_coverage());
    """
    gen_line(vec, tabs) = gen_line_report_coverage(vec, tabs, prefix_name)
    my_str *= """
    $( gen_long_str(vec, "        ", gen_line)[1:end-1] )
            \$sformat(msg, "%s------------------------------------------------------------------------------------------------------------\\n", msg);
            
            //`uvm_info("$(uppercase(prefix_name)) COVERAGE", \$sformatf("Coverage: %2.2f%%", get_coverage()), $(verb_dict["cov_report"]))
            `uvm_info("$(uppercase(prefix_name)) COVERAGE", msg, $(verb_dict["cov_report"]))
        endfunction : report_phase
        
        function void sample ($(tr_type) t);
            cov_transaction = t;
            $(prefix_name)_covergroup.sample();
        endfunction : sample
        
        function real get_coverage ();
            return $(prefix_name)_covergroup.get_inst_coverage();
        endfunction : get_coverage
        
        function void write($(tr_type) t);
            sample(t); // sample coverage with this transaction
            coverage_value = get_coverage();
        endfunction : write
        
    endclass : $(prefix_name)_$(cov_name)
    """
    return my_str
end

gen_clknrst_coverage(prefix_name) = gen_coverage_base(prefix_name)

# ****************************************************************

gen_env_coverage_base() = begin
    cov_name = class_names["coverage"   ]
    if get_usr_cfg_fld(:use_detailed_config_instances) == true
        cfg_name = "env_$(class_names["config"])"
    else
        cfg_name = "$(class_names["config"])"
    end
    @assert size(uvc_names, 1) >= 1
    uvc_name = uvc_names[1]
    tr_name  = get_uvc_cfg_fld(uvc_name, :class_names)["transaction"]
    tr_type = get_uvc_cfg_fld(uvc_name, :uvc_has_params) ? "seq_item_t" : "$(uvc_name)_$(tr_name)"
    
    params_prefix = get_uvc_params_prefix(dut_name)
    
    my_str = """
    class $(dut_name)_$(cov_name) $(get_param_declaration_w_seq_item(params_prefix, "    "))extends uvm_subscriber #($(tr_type));
        
    """

    if env_has_params
        my_str *= """
            `uvm_component_param_utils($(dut_name)_$(cov_name) $(get_param_conn_w_seq_item2(params_prefix, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(dut_name)_$(cov_name))
        """
    end
    
    my_str *= """
        
    $(gen_lines_tdefs_w_param_env(params_prefix, "$(dut_name)_$(cfg_name)", "    ")[1:end-1])
        
        $(dut_name)_$(cfg_name)_t m_$(cfg_name);
    """
    
    my_str *= """
        
        real coverage_value;
        $(tr_type) cov_transaction;
        
        // Use this to connect to more analysis ports
        // `uvm_analysis_imp_decl(_other)
        // uvm_analysis_imp_other #(seq_item_t, $(dut_name)_$(cov_name)_t) other_export;
        // Create this in the new method and write the write_other function
        
        covergroup $(dut_name)_covergroup;
            option.per_instance = 1;
            option.name = {get_full_name(), ".", "covergroup"};
            // option.at_least = 3;
            // option.auto_bin_max = 256;
            // option.cross_auto_bin_max = 256;
    $( gen_long_str(get_uvc_cfg_fld(uvc_name, :tr_props_vec), "        ", gen_line_coverpoint)[1:end-1] )
        endgroup : $(dut_name)_covergroup
        
        function new (string name, uvm_component parent);
            super.new(name, parent);
            $(dut_name)_covergroup = new();
        endfunction : new
        
    """
    my_str *= """
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if (m_$(cfg_name) == null)
                `uvm_fatal("$(uppercase(dut_name)) COVERAGE", "No configuration object was set!")
        endfunction : build_phase
        
    """
    my_str *= """
        function void report_phase (uvm_phase phase);
            string msg;
            super.report_phase(phase);
            
            msg = "";
            \$sformat(msg, "%s \\n------------------------------------------------------------------------------------------------------------\\n", msg);
            \$sformat(msg, "%s FUNCTIONAL COVERAGE SUMMARY \\n", msg);
            \$sformat(msg, "%s \\t- Overview: %.2f%% \\n", msg, $(dut_name)_covergroup.get_inst_coverage());
    """
    gen_line(vec, tabs) = gen_line_report_coverage(vec, tabs, dut_name)
    my_str *= """
    $( gen_long_str(get_uvc_cfg_fld(uvc_name, :tr_props_vec), "        ", gen_line)[1:end-1] )
            \$sformat(msg, "%s------------------------------------------------------------------------------------------------------------\\n", msg);
            
            //`uvm_info("$(uppercase(dut_name)) COVERAGE", \$sformatf("Coverage: %2.2f%%", get_coverage()), $(verbosities["cov_report"]))
            `uvm_info("$(uppercase(dut_name)) COVERAGE", msg, $(verbosities["cov_report"]))
        endfunction : report_phase
        
        function void sample ($(tr_type) t);
            cov_transaction = t;
            $(dut_name)_covergroup.sample();
        endfunction : sample
        
        function real get_coverage ();
            return $(dut_name)_covergroup.get_inst_coverage();
        endfunction : get_coverage
        
        function void write($(tr_type) t);      
            sample(t); // sample coverage with this transaction
            coverage_value = get_coverage();
        endfunction : write
        
    endclass : $(dut_name)_$(cov_name)
    """
    return my_str
end