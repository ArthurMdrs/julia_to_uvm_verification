# ***********************************
# Scoreboard Codes
# ***********************************
# Creates a scoreboard to be added to the environment
# ***********************************


gen_scoreboard_base() = begin
    sb_name = class_names["scoreboard"]
    rm_name = class_names["ref_model" ]
    my_str = """
    class $(dut_name)_$(sb_name) $(get_param_declaration_w_seq_item(params_vec, dut_name, "    "))extends uvm_scoreboard;
        
    """
    
    if has_parameters
        my_str *= """
            `uvm_component_param_utils($(dut_name)_$(sb_name) $(get_param_conn_w_seq_item2(dut_name, "    ")[1:end-1]))
        """
    else
        @assert size(uvc_names, 1) >= 1
        tr_name = get_uvc_cfg_fld(uvc_names[1], :class_names)["transaction"]
        my_str *= """
            `uvm_component_utils($(dut_name)_$(sb_name))
            
            typedef $(uvc_names[1])_$(tr_name) seq_item_t;
        """
    end
    
    my_str *= """
        
        seq_item_t item_from_monitor;
    """
    if gen_refmod
        my_str *= "    seq_item_t item_from_refmod;\n"
    end
    my_str *= """
        
        uvm_tlm_analysis_fifo#(seq_item_t) item_from_monitor_fifo;
    """
    if gen_refmod
        my_str *= "    uvm_tlm_analysis_fifo#(seq_item_t) item_from_refmod_fifo;\n"
    end
    my_str *= """
        
        int unsigned n_compared, n_matches, n_mismatches;
        
        function new(string name="$(dut_name)_$(sb_name)", uvm_component parent = null);
            super.new(name, parent);
            item_from_monitor_fifo = new("item_from_monitor_fifo", this);
    """
    if gen_refmod
        my_str *= "        item_from_refmod_fifo = new(\"item_from_refmod_fifo\", this);\n"
    end
    my_str *= """
        endfunction : new
        
        task post_reset_phase(uvm_phase phase);
            item_from_monitor_fifo.flush();
            item_from_monitor = null;
    """
    if gen_refmod
        my_str *= """
                item_from_refmod_fifo.flush();
                item_from_refmod = null;
        """
    end
    my_str *= """
        endtask : post_reset_phase
        
        task main_phase(uvm_phase phase);
            forever begin
                fork
                    item_from_monitor_fifo.get(item_from_monitor);
    """
    if gen_refmod
        my_str *= "                item_from_refmod_fifo.get(item_from_refmod);\n"
    else
        my_str *= "                //other_fifo.get(other_item);\n"
    end
    my_str *= """
                join
                
                // Place your code here
                `uvm_info("$(uppercase(dut_name)) SCOREBOARD", "Scoreboard activities happening.", UVM_MEDIUM)
                n_compared++;
                
    """
    # if gen_refmod
    #     my_str *= """
    #                 item_from_monitor = null;
    #                 item_from_refmod = null;
    #     """
    # else
    #     my_str *= """
    #                 item_from_monitor = null;
    #                 //other_item = null;
    #     """
    # end
    my_str *= """
            end
        endtask : main_phase
        
        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            
            `uvm_info("$(uppercase(dut_name)) SCOREBOARD", \$sformatf("Compared %0d items.", n_compared), UVM_NONE)
        endfunction : report_phase
        
    endclass : $(dut_name)_$(sb_name)
    """
    return my_str
end