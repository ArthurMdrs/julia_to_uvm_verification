# ***********************************
# Coverage Codes
# ***********************************
# Creates a coverage class
# The gen_coverage_base function needs a vector as an argument
# Form of the vector to generate the class:
#  is_rand? | type | length | name
# 
# E.g.:
# tr_vec = [
#   [true , "bit", "[7:0]", "addr" ],
#   [false, "bit", "[7:0]", "data" ],
#   [false, "bit", "1"    , "value"],
#   [true , "bit", "1"    , "bit_" ]]
#
# This vector comes from the file UVC_parameters/(UVC name)_parameters.jl
# ***********************************

gen_line_coverpoint(vec, tabs) = begin
    if size(vec)[1] > 0
        return """
        $(tabs)$(vec[4])_cp: coverpoint cov_transaction.$(vec[4]) {
        $(tabs)    option.at_least = 2;
        $(tabs)    bins $(vec[4])_bin [] = {[0:$]};
        $(tabs)}
        """
    else
        return ""
    end
end
gen_line_report_coverage(vec, tabs, prefix_name) = begin
    if size(vec)[1] > 0
        return """
        $(tabs)\$sformat(msg, "%s \\t\\t- $(vec[4])_cp: %.2f%% \\n", msg, $(prefix_name)_covergroup.$(vec[4])_cp.get_inst_coverage());
        """
    else
        return ""
    end
end

gen_coverage_base(prefix_name, vec) = begin
    cov_name = use_short_names ? short_names_dict["coverage"   ] : long_names_dict["coverage"   ]
    cfg_name = use_short_names ? short_names_dict["config"     ] : long_names_dict["config"     ]
    tr_name  = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
    tr_type = has_paramaters ? "seq_item_t" : "$(prefix_name)_$(tr_name)"
    my_str = """
    class $(prefix_name)_$(cov_name) $(get_param_declaration_w_seq_item(params_vec, dut_name, "    "))extends uvm_subscriber #($(tr_type));
        
    $( gen_long_str(["$(prefix_name)_$(cfg_name)"], "    ", gen_lines_tdefs_w_param) )
        $(prefix_name)_$(cfg_name)_t $(config_inst_convention);
        
        real coverage_value;
        $(tr_type) cov_transaction;
        
    """

    if has_paramaters
        my_str *= """
            `uvm_component_param_utils_begin($(prefix_name)_$(cov_name) $(get_param_conn_w_seq_item2("    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils_begin($(prefix_name)_$(cov_name))
        """
    end
    
    my_str *= """
            `uvm_field_object($(config_inst_convention), UVM_ALL_ON)
            `uvm_field_real(coverage_value, UVM_ALL_ON)
        `uvm_component_utils_end
        
        covergroup $(prefix_name)_covergroup;
            option.per_instance = 1;
            option.name = {get_full_name(), ".", "covergroup"};
            // option.at_least = 3;
            // option.auto_bin_max = 256;
            // option.cross_auto_bin_max = 256;
    $(gen_long_str(vec, "        ", gen_line_coverpoint))    endgroup : $(prefix_name)_covergroup
        
        function new (string name, uvm_component parent);
            super.new(name, parent);
            $(prefix_name)_covergroup = new();
        endfunction: new
        
        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            if(uvm_config_db#($(prefix_name)_$(cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("$(config_inst_convention)"), .value($(config_inst_convention))))
                `uvm_info("$(uppercase(prefix_name)) COVERAGE", "Configuration object was successfully set!", UVM_MEDIUM)
            else
                `uvm_fatal("$(uppercase(prefix_name)) COVERAGE", "No configuration object was set!")
        endfunction: build_phase
        
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
            
            //`uvm_info("$(uppercase(prefix_name)) COVERAGE", \$sformatf("Coverage: %2.2f%%", get_coverage()), UVM_NONE)
            `uvm_info("$(uppercase(prefix_name)) COVERAGE", msg, UVM_NONE)
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

gen_clknrst_coverage() = gen_coverage_base("clknrst", [])

# ****************************************************************

gen_env_coverage_base() = begin
    cov_name = use_short_names ? short_names_dict["coverage"   ] : long_names_dict["coverage"   ]
    cfg_name = use_short_names ? short_names_dict["config"     ] : long_names_dict["config"     ]
    tr_name  = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
    @assert size(uvc_names, 1) >= 1
    uvc_name = uvc_names[1]
    tr_type = has_paramaters ? "seq_item_t" : "$(uvc_name)_$(tr_name)"
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    my_str = """
    class $(dut_name)_$(cov_name) $(get_param_declaration_w_seq_item(params_vec, dut_name, "    "))extends uvm_subscriber #($(tr_type));
        
    """
    # my_str *= """
    # $( gen_long_str(["$(dut_name)_$(cfg_name)"], "    ", gen_lines_tdefs_w_param) )
    #     $(dut_name)_$(cfg_name)_t $(config_inst_convention);
    # """
    my_str *= """
        real coverage_value;
        $(tr_type) cov_transaction;
        
    """

    if has_paramaters
        my_str *= """
            `uvm_component_param_utils_begin($(dut_name)_$(cov_name) $(get_param_conn_w_seq_item2("    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils_begin($(dut_name)_$(cov_name))
        """
    end
    
            # `uvm_field_object($(config_inst_convention), UVM_ALL_ON)
    my_str *= """
            `uvm_field_real(coverage_value, UVM_ALL_ON)
        `uvm_component_utils_end
        
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
    $(gen_long_str(tr_vec, "        ", gen_line_coverpoint))    endgroup : $(dut_name)_covergroup
        
        function new (string name, uvm_component parent);
            super.new(name, parent);
            $(dut_name)_covergroup = new();
        endfunction: new
        
    """
    # my_str *= """
    #     function void build_phase (uvm_phase phase);
    #         super.build_phase(phase);
    #         if(uvm_config_db#($(dut_name)_$(cfg_name)_t)::get(.cntxt(this), .inst_name(""), .field_name("$(config_inst_convention)"), .value($(config_inst_convention))))
    #             `uvm_info("$(uppercase(dut_name)) COVERAGE", "Configuration object was successfully set!", UVM_MEDIUM)
    #         else
    #             `uvm_fatal("$(uppercase(dut_name)) COVERAGE", "No configuration object was set!")
    #     endfunction: build_phase
        
    # """
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
    $( gen_long_str(tr_vec, "        ", gen_line)[1:end-1] )
            \$sformat(msg, "%s------------------------------------------------------------------------------------------------------------\\n", msg);
            
            //`uvm_info("$(uppercase(dut_name)) COVERAGE", \$sformatf("Coverage: %2.2f%%", get_coverage()), UVM_NONE)
            `uvm_info("$(uppercase(dut_name)) COVERAGE", msg, UVM_NONE)
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
    restore_config()
    return my_str
end