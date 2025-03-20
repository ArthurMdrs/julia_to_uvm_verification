# ***********************************
# Transaction Codes
# ***********************************
# Creates an transaction class (a.k.a. sequence item)
# ***********************************
gen_line_convert_to_string(vec::tr_field_t, tabs) = 
    "$(tabs)string_aux = {string_aux, \$sformatf(\"** $(vec.field_name) value: %h\\n\", $(vec.field_name))};\n"
# gen_line_object_utils(vec::tr_field_t, tabs) = 
#     "$(tabs)`uvm_field_int($(vec.field_name), UVM_ALL_ON)\n"
gen_line_instanciate_obj(vec::tr_field_t, tabs) = 
    "$(tabs)$((vec.is_rand) ? "rand" : "    ") $(vec.type) $(vec.range) $(vec.field_name);\n"

gen_line_attribute_copy(vec::tr_field_t, tabs) = begin
    my_str = "$(tabs)$(vec.field_name) = _rhs.$(vec.field_name);\n"
    return my_str
end
gen_do_copy(prefix_name, vec::Vector{tr_field_t}) = begin
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    my_str = """
        function void do_copy (uvm_object rhs);
            $(prefix_name)_$(tr_name) $(get_param_conn(dut_name, "        "))_rhs;
            
            \$cast(_rhs, rhs);
            
            super.do_copy(rhs);
            
    $( gen_long_str(vec, "        ", gen_line_attribute_copy)[1:end-1] )
        endfunction : do_copy
    """
    return my_str
end
gen_line_attribute_comp(vec::tr_field_t, tabs) = begin
    my_str = "$(tabs)res = res && ($(vec.field_name) === _rhs.$(vec.field_name));\n"
    return my_str
end
gen_do_compare(prefix_name, vec::Vector{tr_field_t}) = begin
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    my_str = """
        function bit do_compare (uvm_object rhs, uvm_comparer comparer);
            bit res;
            $(prefix_name)_$(tr_name) $(get_param_conn(dut_name, "        "))_rhs;
            
            \$cast(_rhs, rhs);
            
            res = super.do_compare(rhs, comparer);
            
    $( gen_long_str(vec, "        ", gen_line_attribute_comp)[1:end-1] )
            
            return res;
        endfunction : do_compare
    """
    return my_str
end
gen_do_print(prefix_name, vec::Vector{tr_field_t}) = begin
    my_str = """
        function void do_print (uvm_printer printer);
            if (printer.knobs.sprint == 0)
                `uvm_info(get_type_name(), convert2string(), UVM_MEDIUM)
            else
                printer.m_string = convert2string();
        endfunction : do_print
    """
    return my_str
end
gen_line_attribute_record(vec::tr_field_t, tabs) = begin
    my_str = "$(tabs)`uvm_record_field(\"$(vec.field_name)\", $(vec.field_name))\n"
    return my_str
end
gen_do_record(prefix_name, vec::Vector{tr_field_t}) = begin
    my_str = """
        function void do_record (uvm_recorder recorder);
            super.do_record(recorder);
            
            // Use the example below to record integral types
            // `uvm_record_int("m_some_property", m_some_property, 32, UVM_DEC)
            
    $( gen_long_str(vec, "        ", gen_line_attribute_record)[1:end-1] )
        endfunction : do_record
    """
    return my_str
end
gen_line_attribute_pack(vec::tr_field_t, tabs) = begin
    my_str = "$(tabs)`uvm_pack_int($(vec.field_name))\n"
    return my_str
end
gen_do_pack(prefix_name, vec::Vector{tr_field_t}) = begin
    my_str = """
        function void do_pack (uvm_packer packer);
            super.do_pack(packer);
            
            // `uvm_pack_array needs packer.use_metadata==1
    $( gen_long_str(vec, "        ", gen_line_attribute_pack)[1:end-1] )
        endfunction : do_pack
    """
    return my_str
end
gen_line_attribute_unpack(vec::tr_field_t, tabs) = begin
    my_str = "$(tabs)`uvm_unpack_int($(vec.field_name))\n"
    return my_str
end
gen_do_unpack(prefix_name, vec::Vector{tr_field_t}) = begin
    my_str = """
        function void do_unpack (uvm_packer packer);
            super.do_unpack(packer);
            
            // `uvm_unpack_enum(some_enum_var, some_enum_type)
            // `uvm_unpack_array needs packer.use_metadata==1
    $( gen_long_str(vec, "        ", gen_line_attribute_unpack)[1:end-1] )
        endfunction : do_unpack
    """
    return my_str
end

gen_tr_base(prefix_name) = begin 
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    vec = get_uvc_cfg_fld(prefix_name, :tr_props_vec)
    my_str = """
    class $(prefix_name)_$(tr_name) $(get_param_declaration(params_vec, dut_name, "    "))extends uvm_sequence_item;
        
    """
    
    if has_parameters
        my_str *= """
            `uvm_object_param_utils($(prefix_name)_$(tr_name) $(get_param_conn(dut_name, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_object_utils($(prefix_name)_$(tr_name))
        """
    end
    
    my_str *= """
        
    $( gen_long_str(vec, "    ", gen_line_instanciate_obj)[1:end-1] )
        
        function new(string name="$(prefix_name)_$(tr_name)");
            super.new(name);
        endfunction : new
        
        // Type your constraints!
        // constraint some_constraint { some_property >= 0;}
        
        function string convert2string();
            string string_aux;
            
            string_aux = {string_aux, "\\n***********************************\\n"};
    $( gen_long_str(vec, "        ", gen_line_convert_to_string)[1:end-1] )
            string_aux = {string_aux, "***********************************"};
            return string_aux;
        endfunction : convert2string
        
        // function void post_randomize();
        // endfunction : post_randomize
        
    """
    my_str *= """
    $( gen_do_copy(prefix_name, vec)[1:end-1] )
        
    $( gen_do_compare(prefix_name, vec)[1:end-1] )
        
    $( gen_do_print(prefix_name, vec)[1:end-1] )
        
    $( gen_do_record(prefix_name, vec)[1:end-1] )
        
    $( gen_do_pack(prefix_name, vec)[1:end-1] )
        
    $( gen_do_unpack(prefix_name, vec)[1:end-1] )
        
    """
    my_str *= """
    endclass : $(prefix_name)_$(tr_name)
    """
    return my_str
end

gen_clknrst_tr(prefix_name) = begin 
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    my_str = """
    class $(prefix_name)_$(tr_name) $(get_param_declaration(params_vec, dut_name, "    "))extends uvm_sequence_item;
        
    """
    
    if has_parameters
        my_str *= """
            `uvm_object_param_utils($(prefix_name)_$(tr_name) $(get_param_conn(dut_name, "    ")[1:end-1]))
        """
    else
        my_str *= """
            `uvm_object_utils($(prefix_name)_$(tr_name))
        """
    end
    
    my_str *= """
        
        rand $(prefix_name)_action_enum_t   action;
        rand int unsigned            rst_assert_duration;     // In ps
        rand int unsigned            clk_period;              // In ps
        rand $(prefix_name)_init_val_enum_t initial_clk_val;
        
        
        function new(string name="$(prefix_name)_$(tr_name)");
            super.new(name);
        endfunction : new
        
        constraint max_clk_period {
            clk_period <= 20_000; // 20ns
        }
        constraint min_clk_period {
            clk_period > 2_000; // 2ns (clocking blocks use 1ns for input and output)
        }
        
        constraint max_rst_assert_duration {
            rst_assert_duration <= 15_000; // 15ns
        }
        
    endclass : $(prefix_name)_$(tr_name)
    """
    return my_str
end

# ****************************************************************