# The functions below will be used in many files, so we
# will declare them here to avoid repeating code
gen_long_str(vec, tabs, line_gen_func) = begin
    str_aux = ""
    for x in vec
        str_aux *= line_gen_func(x, tabs)
    end
    return str_aux
end
output_file_setup(dir; reset_folder=true) = begin
    if isdir(dir)
        if (reset_folder)
            rm(dir, recursive=true, force = true)
            mkdir(dir)
        end
    else
        mkdir(dir)
    end
end
write_file(file_dir, txt_string) = begin
    open(file_dir, "w") do io
        write(io, txt_string)
    end;
end

get_usr_cfg_fld(field::Symbol) = begin
    if isdefined(user_config, field) && getfield(user_config, field) != nothing
        # println("usr")
        return getfield(user_config, field)
    elseif isdefined(global_config, field) && getfield(global_config, field) != nothing
        # println("glob")
        return getfield(global_config, field)
    else
        error("Trying to access non-existent config field: $(String(field)).")
    end
end

get_uvc_cfg_fld(uvc_name::String, field::Symbol) = begin
    if isdefined(uvc_config_dict[uvc_name], field) && getfield(uvc_config_dict[uvc_name], field) != nothing
        # println("uvc_name")
        return getfield(uvc_config_dict[uvc_name], field)
    elseif isdefined(user_config, field) && getfield(user_config, field) != nothing
        # println("usr")
        return getfield(user_config, field)
    elseif isdefined(global_config, field) && getfield(global_config, field) != nothing
        # println("glob")
        return getfield(global_config, field)
    else
        error("Trying to access non-existent UVC config field: $(String(field)).")
    end
end

gen_line_import(uvc_name, tabs) = begin
    return """
    $(tabs)import $(uvc_name)_pkg::*;
    """
end

gen_line_vif_instance(uvc_name, tabs) = begin
    return """$(tabs)$(uvc_name)_vif_t $(uvc_name)_vif;\n"""
end

gen_line_vif_typedef(uvc_name, tabs) = begin
    if_name = get_uvc_cfg_fld(uvc_name, :class_names)["interface"]
    my_str = "$(tabs)typedef virtual interface $(uvc_name)_$(if_name) $(get_param_conn(dut_name, tabs))$(uvc_name)_vif_t;\n"
    return my_str
end

gen_vif_config_db_component(uvc_name, tabs, class_name) = begin
    agent_name = get_uvc_cfg_fld(uvc_name, :class_names)["agent"]
    return """
        $(tabs)if(uvm_config_db#($(uvc_name)_vif_t)::get(.cntxt(this), .inst_name(""), .field_name("vif"), .value(vif)))
        $(tabs)    `uvm_info("$(uppercase(uvc_name)) $(uppercase(class_name))", "Virtual interface was successfully set!", UVM_MEDIUM)
        $(tabs)else
        $(tabs)    `uvm_fatal("$(uppercase(uvc_name)) $(uppercase(class_name))", "No virtual interface was set!")
        """
end

gen_line_if_signal(vec::if_field_t, tabs; end_of_line=";") = begin
    return "$(tabs)$(vec.type) $(vec.range) $(vec.field_name)$(end_of_line)\n"
end

get_param_declaration(params_vec, prefix_name, tabs) = begin
    my_str = ""
    if has_paramaters
        my_str *= "#(\n"
        my_str *= "$(tabs)parameter $(prefix_name)_params_t $(prefix_name)_params = '0\n"
        my_str *= ") "
    end
    return my_str
end

get_param_declaration_w_seq_item(params_vec, prefix_name, tabs) = begin
    my_str = ""
    if has_paramaters
        my_str *= """
        #(
        $(tabs)parameter type seq_item_t = uvm_sequence_item,
        $(tabs)parameter $(prefix_name)_params_t $(prefix_name)_params = '0
        ) """
    end
    return my_str
end

get_param_conn(prefix_name, tabs) = begin
    if has_paramaters
        my_str = "#(\n$(tabs)    .$(prefix_name)_params($(prefix_name)_params)\n$(tabs)) "
    else
        my_str = ""
    end
    return my_str
end

get_param_conn_w_seq_item(prefix_name, tabs) = begin
    if has_paramaters
        tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
        my_str = """
        #(
        $(tabs)    .seq_item_t($(prefix_name)_$(tr_name)_t),
        $(tabs)    .$(dut_name)_params($(dut_name)_params)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end

get_param_conn_w_seq_item2(prefix_name, tabs) = begin
    if has_paramaters
        my_str = """
        #(
        $(tabs)    .seq_item_t(seq_item_t),
        $(tabs)    .$(prefix_name)_params($(prefix_name)_params)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end

gen_vsqr_param_conn(tabs) = begin
    if has_paramaters
        my_str = """
        #(
        $( gen_long_str(uvc_names, "$(tabs)    ", gen_line_seq_item_t_conn)[1:end-1] )
        $(tabs)    .$(dut_name)_params($(dut_name)_params)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end

gen_lines_tdefs_w_param(name, tabs) = begin
    my_str = "$(tabs)typedef $(name) $(get_param_conn(dut_name, tabs))$(name)_t;\n"
    return my_str
end

gen_lines_tdefs_w_param_w_seq_item(name, uvc_name, tabs) = begin
    my_str = "$(tabs)typedef $(name) $(get_param_conn_w_seq_item(uvc_name, tabs))$(name)_t;\n"
    return my_str
end

gen_lines_tdefs_w_param_w_seq_item2(name, tabs) = begin
    my_str = "$(tabs)typedef $(name) $(get_param_conn_w_seq_item2(dut_name, tabs))$(name)_t;\n"
    return my_str
end

gen_lines_tdefs_wo_param(name, tabs) = begin
    my_str  = "$(tabs)typedef $(name) $(name)_t;\n\n"
    return my_str
end

gen_line_seq_item_t_conn(uvc_name, tabs) = begin
    tr_name = get_uvc_cfg_fld(uvc_name, :class_names)["transaction"]
    my_str = "$(tabs).$(uvc_name)_$(tr_name)_t($(uvc_name)_$(tr_name)_t),\n"
    return my_str
end

gen_line_cfg_instance(uvc_name, tabs) = begin
    cfg_name = get_uvc_cfg_fld(uvc_name, :class_names)["config"]
    return """$(tabs)$(uvc_name)_$(cfg_name)_t m_$(uvc_name)_$(cfg_name);\n"""
end

gen_line_import_tdefs(uvc_name, tabs) = begin
    if get_uvc_cfg_fld(uvc_name, :gen_tdefs_pkg) == true
        return """
        $(tabs)import $(uvc_name)_tdefs_pkg::*;
        """
    else
        return ""
    end
end


