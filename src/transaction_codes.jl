# ***********************************
# Transaction Codes
# ***********************************
# Creates an transaction class (a.k.a. sequence item)
# ***********************************
gen_line_convert_to_string(vec::tr_field_t, tabs) = begin
    if vec.radix == "dec"
        fmt = "%0d"
    elseif vec.radix == "bin"
        fmt = "%b"
    elseif vec.radix == "hex"
        fmt = "%h"
    end
    if vec.type in packed_types
        if size(vec.size)[1] == 1
            my_str = "$(tabs)string_aux = {string_aux, \$sformatf(\"** $(vec.field_name) value: $(fmt)\\n\", $(vec.field_name))};\n"
        else
            my_str  = "$(tabs)foreach ($(vec.field_name)[i])\n"
            my_str *= "$(tabs)    string_aux = {string_aux, \$sformatf(\"** $(vec.field_name)[%0d] value: $(fmt)\\n\", i, $(vec.field_name)[i])};\n"
        end
    elseif vec.type in integer_types
        if size(vec.size)[1] == 1 && vec.size == 1
            my_str = "$(tabs)string_aux = {string_aux, \$sformatf(\"** $(vec.field_name) value: $(fmt)\\n\", $(vec.field_name))};\n"
        else
            my_str  = "$(tabs)foreach ($(vec.field_name)[i])\n"
            my_str *= "$(tabs)    string_aux = {string_aux, \$sformatf(\"** $(vec.field_name)[%0d] value: $(fmt)\\n\", i, $(vec.field_name)[i])};\n"
        end
    elseif vec.type == "string"
        my_str = "$(tabs)string_aux = {string_aux, \$sformatf(\"** $(vec.field_name) value: %s\\n\", $(vec.field_name))};\n"
    elseif vec.type in real_types
        my_str = "$(tabs)string_aux = {string_aux, \$sformatf(\"** $(vec.field_name) value: %.2f\\n\", $(vec.field_name))};\n"
    else
        my_str = ""
    end
    return my_str
end
gen_line_instanciate_obj(vec::tr_field_t, tabs) = begin
    if vec.type in packed_types
        return "$(tabs)$((vec.is_rand) ? "rand " : "")$(vec.type) $(get_signal_range(vec))$(vec.field_name);\n"
    else
        return "$(tabs)$((vec.is_rand) ? "rand " : "")$(vec.type) $(vec.field_name)$(get_signal_dim(vec));\n"
    end
end
gen_line_attribute_copy(vec::tr_field_t, tabs) = begin
    my_str = "$(tabs)$(vec.field_name) = _rhs.$(vec.field_name);\n"
    return my_str
end
gen_do_copy(prefix_name, vec::Vector{tr_field_t}) = begin
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    my_str = """
        function void do_copy (uvm_object rhs);
            $(prefix_name)_$(tr_name) $(get_param_conn(params_prefix, "        "))_rhs;
            
            \$cast(_rhs, rhs);
            
            super.do_copy(rhs);
            
    $( gen_long_str(vec, "        ", gen_line_attribute_copy)[1:end-1] )
        endfunction : do_copy
    """
    return my_str
end
gen_line_attribute_comp(vec::tr_field_t, tabs) = begin
    if vec.type in integer_types
        my_str = "$(tabs)res = res && ($(vec.field_name) === _rhs.$(vec.field_name));\n"
    else
        my_str = "$(tabs)res = res && ($(vec.field_name) == _rhs.$(vec.field_name));\n"
    end
    return my_str
end
gen_do_compare(prefix_name, vec::Vector{tr_field_t}) = begin
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    my_str = """
        function bit do_compare (uvm_object rhs, uvm_comparer comparer);
            bit res;
            $(prefix_name)_$(tr_name) $(get_param_conn(params_prefix, "        "))_rhs;
            
            \$cast(_rhs, rhs);
            
            res = super.do_compare(rhs, comparer);
            
    $( gen_long_str(vec, "        ", gen_line_attribute_comp)[1:end-1] )
            
            return res;
        endfunction : do_compare
    """
    return my_str
end
gen_do_print(prefix_name, vec::Vector{tr_field_t}) = begin
    # TODO: make the uvm verbority below configurable?
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
gen_line_attribute_record_field(vec::tr_field_t, tabs) = begin
    my_str = "$(tabs)`uvm_record_field(\"$(vec.field_name)\", $(vec.field_name))\n"
    return my_str
end
gen_line_attribute_record_int(vec::tr_field_t, tabs) = begin
    if vec.type in packed_types
        if size(vec.size)[1] == 1
            my_str = "$(tabs)`uvm_record_int(\"$(vec.field_name)\", $(vec.field_name), $(vec.size[1]), UVM_$(uppercase(vec.radix)))\n"
        else
            my_str  = "$(tabs)foreach ($(vec.field_name)[i])\n"
            my_str *= "$(tabs)    `uvm_record_int(\$sformatf(\"$(vec.field_name)[%0d]\", i), $(vec.field_name)[i], $(vec.size[2]), UVM_$(uppercase(vec.radix)))\n"
        end
    else
        if size(vec.size)[1] == 1 && vec.size == 1
            my_str = "$(tabs)`uvm_record_int(\"$(vec.field_name)\", $(vec.field_name), $(vec.size[1]), UVM_$(uppercase(vec.radix)))\n"
        else
            my_str  = "$(tabs)foreach ($(vec.field_name)[i])\n"
            my_str *= "$(tabs)    `uvm_record_int(\$sformatf(\"$(vec.field_name)[%0d]\", i), $(vec.field_name)[i], $(vec.size[1]), UVM_$(uppercase(vec.radix)))\n"
        end
    end
    return my_str
end
gen_line_attribute_record_string(vec::tr_field_t, tabs) = begin
    my_str = "$(tabs)`uvm_record_string(\"$(vec.field_name)\", $(vec.field_name))\n"
    return my_str
end
gen_line_attribute_record_real(vec::tr_field_t, tabs) = begin
    my_str = "$(tabs)`uvm_record_real(\"$(vec.field_name)\", $(vec.field_name))\n"
    return my_str
end
gen_line_attribute_record(vec::tr_field_t, tabs) = begin
    if vec.type in integer_types
        return gen_line_attribute_record_int(vec, tabs)
    elseif vec.type in real_types
        return gen_line_attribute_record_real(vec, tabs)
    elseif vec.type == "string"
        return gen_line_attribute_record_string(vec, tabs)
    else
        return gen_line_attribute_record_field(vec, tabs)
    end
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
gen_line_attribute_pack_unpack(vec::tr_field_t, tabs, un) = begin
    if vec.type in packed_types
        if size(vec.size)[1] == 1
            my_str = "$(tabs)`uvm_$(un)pack_int($(vec.field_name))\n"
        else
            my_str  = "$(tabs)foreach ($(vec.field_name)[i])\n"
            my_str *= "$(tabs)    `uvm_$(un)pack_int($(vec.field_name)[i])\n"
        end
    elseif vec.type in integer_types
        if size(vec.size)[1] == 1 && vec.size == 1
            my_str = "$(tabs)`uvm_$(un)pack_int($(vec.field_name))\n"
        else
            my_str  = "$(tabs)foreach ($(vec.field_name)[i])\n"
            my_str *= "$(tabs)    `uvm_$(un)pack_int($(vec.field_name)[i])\n"
        end
    elseif vec.type == "string"
        my_str = "$(tabs)`uvm_$(un)pack_string($(vec.field_name))\n"
    elseif vec.type in real_types
        my_str = "$(tabs)`uvm_$(un)pack_real($(vec.field_name))\n"
    else
        my_str = ""
    end
    return my_str
end
gen_line_attribute_pack(vec::tr_field_t, tabs) = begin
    return gen_line_attribute_pack_unpack(vec, tabs, "")
end
gen_do_pack(prefix_name, vec::Vector{tr_field_t}) = begin
    my_str = """
        function void do_pack (uvm_packer packer);
            super.do_pack(packer);
            
    $( gen_long_str(vec, "        ", gen_line_attribute_pack)[1:end-1] )
        endfunction : do_pack
    """
    return my_str
end
gen_line_attribute_unpack(vec::tr_field_t, tabs) = begin
    return gen_line_attribute_pack_unpack(vec, tabs, "")
end
gen_do_unpack(prefix_name, vec::Vector{tr_field_t}) = begin
    my_str = """
        function void do_unpack (uvm_packer packer);
            super.do_unpack(packer);
            
            // `uvm_unpack_enum(some_enum_var, some_enum_type)
    $( gen_long_str(vec, "        ", gen_line_attribute_unpack)[1:end-1] )
        endfunction : do_unpack
    """
    return my_str
end

gen_tr_base(prefix_name) = begin 
    tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
    vec = get_uvc_cfg_fld(prefix_name, :tr_props_vec)
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    my_str = """
    class $(prefix_name)_$(tr_name) $(get_param_declaration(params_prefix, "    "))extends uvm_sequence_item;
        
    """
    
    if get_uvc_cfg_fld(prefix_name, :uvc_has_params)
        my_str *= """
            `uvm_object_param_utils($(prefix_name)_$(tr_name) $(get_param_conn(params_prefix, "    ")[1:end-1]))
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
    
    params_prefix = get_uvc_params_prefix(prefix_name)
    
    my_str = """
    class $(prefix_name)_$(tr_name) $(get_param_declaration(params_prefix, "    "))extends uvm_sequence_item;
        
    """
    
    if get_uvc_cfg_fld(prefix_name, :uvc_has_params)
        my_str *= """
            `uvm_object_param_utils($(prefix_name)_$(tr_name) $(get_param_conn(params_prefix, "    ")[1:end-1]))
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