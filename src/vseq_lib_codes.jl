# ***********************************
# Virtual Sequence Lib Codes
# ***********************************
# Creates a virtual sequence library to be used by the virtual sequencer
# ***********************************

gen_line_seq_instance(seq_name, tabs) = begin
    my_str = "$(tabs)$(seq_name)_t m_$(seq_name);\n"
    return my_str
end
gen_line_rnd_seq_creation(uvc_name, tabs) = begin
    my_str = "$(tabs)m_$(uvc_name)_random_seq = $(uvc_name)_random_seq_t::type_id::create(\"m_$(uvc_name)_random_seq\");\n"
    return my_str
end
gen_line_rnd_seq_set_phase(uvc_name, tabs) = begin
    my_str = "$(tabs)m_$(uvc_name)_random_seq.set_starting_phase(get_starting_phase());\n"
    return my_str
end
gen_line_rnd_seq_start(uvc_name, tabs) = begin
    sqr_name = get_uvc_cfg_fld(uvc_name, :class_names)["sequencer"]
    my_str = "$(tabs)m_$(uvc_name)_random_seq.start(.sequencer(p_sequencer.m_$(uvc_name)_$(sqr_name)), .call_pre_post(0));\n"
    return my_str
end

gen_vseq_base() = begin
    vsqr_name = class_names["vsequencer"]
    sqr_name  = class_names["sequencer" ]
    my_str = """
    class $(dut_name)_base_vsequence $(get_vsqr_param_declaration("    "))extends uvm_sequence;
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_object_param_utils($(dut_name)_base_vsequence $(get_vsqr_param_conn("    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_object_utils($(dut_name)_base_vsequence)
        """
    end
    
    my_str *= """
    
        // Typedefs - begin
    """
    
    seq_list = []
    if using_this_clknrst == true
        for x in clknrst_actions_vec
            push!(seq_list, clknrst_name*"_"*x*"_seq")
        end
        push!(seq_list, "$(clknrst_name)_reset_and_start_clk_seq")
    end
    for x in seq_list
        my_str *= gen_lines_tdefs_w_param_w_seq_item(x, clknrst_name, "    ")
    end
    for uvc_name in uvc_names
        if uvc_name == clknrst_name && using_this_clknrst == true
            continue
        end
        push!(seq_list, "$(uvc_name)_random_seq")
        my_str *= gen_lines_tdefs_w_param_w_seq_item("$(uvc_name)_random_seq", uvc_name, "    ")
    end
    
    my_str *= """ 
    $( gen_vsqr_tdef("    ")[1:end-1] )
        // Typedefs - end 
        
        `uvm_declare_p_sequencer($(dut_name)_$(vsqr_name)_t)
        
        // Sequence instances - begin
    $( gen_long_str(seq_list, "    ", gen_line_seq_instance)[1:end-1] )
        // Sequence instances - end
        
        function new(string name="$(dut_name)_base_vsequence");
            super.new(name);
        endfunction : new
        
    """
    
    my_str *= """
        task pre_start();
            uvm_phase phase = get_starting_phase();
            if (phase != null) begin
                phase.raise_objection(this, get_type_name());
                `uvm_info("$(uppercase(dut_name)) vSEQ", "Raising objection.", UVM_HIGH)
            end
            else begin
                `uvm_info("$(uppercase(dut_name)) vSEQ", "Phase is null, so could not raise objection.", UVM_LOW)
            end
        
            //$(config_inst_convention) = p_sequencer.$(config_inst_convention);
        endtask : pre_start
        
        task post_start();
            uvm_phase phase = get_starting_phase();
            if (phase != null) begin
                phase.drop_objection(this, get_type_name());
                `uvm_info("$(uppercase(dut_name)) vSEQ", "Dropping objection.", UVM_HIGH)
            end
            else begin
                `uvm_info("$(uppercase(dut_name)) vSEQ", "Phase is null, so could not drop objection.", UVM_LOW)
            end
        endtask : post_start
        
    """
    # my_str *= """ 
    #     task pre_body();
    #         uvm_phase phase = get_starting_phase();
    #         phase.raise_objection(this, get_type_name());
    #         `uvm_info("$(dut_name Sequence", "phase.raise_objection", UVM_HIGH)
    #     endtask : pre_body
        
    #     task post_body();
    #         uvm_phase phase = get_starting_phase();
    #         phase.drop_objection(this, get_type_name());
    #         `uvm_info("$(dut_name Sequence", "phase.drop_objection", UVM_HIGH)
    #     endtask : post_body
        
    # """
    
    my_str *= """ 
    endclass : $(dut_name)_base_vsequence
    """
    return my_str
end

gen_vseq_random() = begin
    sqr_name  = class_names["sequencer" ]
    
    uvc_names_ = uvc_names
    if using_this_clknrst == true
        uvc_names_ = filter(x -> x!= clknrst_name, uvc_names)
    end
    
    my_str = """
    class $(dut_name)_random_vseq $(get_vsqr_param_declaration("    "))extends $(dut_name)_base_vsequence$(gen_vsqr_param_conn("")[1:end-1]);
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_object_param_utils($(dut_name)_random_vseq $(get_vsqr_param_conn("    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_object_utils($(dut_name)_random_vseq)
        """
    end
    
    my_str *= """
        
        function new(string name="$(dut_name)_random_vseq");
            super.new(name);
        endfunction : new
        
        task body();
    """
    
    if using_this_clknrst == true
        my_str *= "        m_clknrst_reset_and_start_clk_seq = clknrst_reset_and_start_clk_seq_t::type_id::create(\"m_clknrst_reset_and_start_clk_seq\");\n"
    else
        my_str *= ""
    end
    
    my_str *= """
    $( gen_long_str(uvc_names_, "        ", gen_line_rnd_seq_creation)[1:end-1] )
            
    """
    
    if using_this_clknrst == true
        my_str *= "        m_clknrst_reset_and_start_clk_seq.set_starting_phase(get_starting_phase());\n"
    else
        my_str *= ""
    end
    
    my_str *= """
    $( gen_long_str(uvc_names_, "        ", gen_line_rnd_seq_set_phase)[1:end-1] )
            
    """
    
    if using_this_clknrst == true
        my_str *= "        m_clknrst_reset_and_start_clk_seq.start(.sequencer(p_sequencer.m_clknrst_$(sqr_name)), .call_pre_post(0));\n"
    else
        my_str *= ""
    end
    
    my_str *= """
            
            fork
    $( gen_long_str(uvc_names_, "            ", gen_line_rnd_seq_start)[1:end-1] )
            join
            
        endtask : body
        
    endclass : $(dut_name)_random_vseq
    """
    return my_str
end
