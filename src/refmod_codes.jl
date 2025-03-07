# ***********************************
# Reference Model Codes
# ***********************************
# Creates a reference model to be added to the environment
# ***********************************


gen_refmod_base() = begin
    rm_name = class_names["ref_model"]
    my_str = """
    class $(dut_name)_$(rm_name) $(get_param_declaration_w_seq_item(params_vec, dut_name, "    "))extends uvm_subscriber#(seq_item_t);
        
    """
    
    if has_paramaters
        my_str *= """
            `uvm_component_param_utils($(dut_name)_$(rm_name) $(get_param_conn_w_seq_item2(dut_name, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_component_utils($(dut_name)_$(rm_name))
        """
    end
    
    my_str *= """
        
        seq_item_t seq_item;
        
        uvm_analysis_port#(seq_item_t) $(rm_name)_port;
        
        function new(string name="$(dut_name)_$(rm_name)", uvm_component parent = null);
            super.new(name, parent);
            $(rm_name)_port = new("$(rm_name)_port", this);
        endfunction : new
        
        function void write(seq_item_t t);
            seq_item = seq_item_t::type_id::create("seq_item");
            
            seq_item.copy(t);
            
            $(rm_name)_port.write(seq_item);
            
            `uvm_info("$(uppercase(dut_name)) REFMOD", \$sformatf("Processed item: \\n%s", seq_item.convert2string()), UVM_HIGH)
        endfunction : write
        
    endclass : $(dut_name)_$(rm_name)
    """
    return my_str
end