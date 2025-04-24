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

vector_to_pattern(prefix_name) = begin
    vec_out = []
    for class_symbol in fieldnames(typeof(pkg_classes))
        class_name = String(class_symbol)
        if String(class_symbol) == "coverage"
            if get_uvc_cfg_fld(prefix_name, :agent_has_coverage) == true
                class_name = get_uvc_cfg_fld(prefix_name, :class_names)[class_name]
                push!(vec_out, prefix_name*"_"*class_name)
            end
        elseif getfield(pkg_classes, class_symbol) == true
            class_name = get_uvc_cfg_fld(prefix_name, :class_names)[class_name]
            push!(vec_out, prefix_name*"_"*class_name)
        end
    end
    return vec_out
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
    params_prefix = get_uvc_params_prefix(uvc_name)
    my_str = "$(tabs)typedef virtual interface $(uvc_name)_$(if_name) $(get_param_conn(params_prefix, tabs))$(uvc_name)_vif_t;\n"
    return my_str
end

gen_line_vif_typedef_env(uvc_name, tabs) = begin
    if_name = get_uvc_cfg_fld(uvc_name, :class_names)["interface"]
    params_prefix = get_uvc_params_prefix(uvc_name)
    my_str = "$(tabs)typedef virtual interface $(uvc_name)_$(if_name) $(get_param_conn_env(params_prefix, tabs))$(uvc_name)_vif_t;\n"
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

get_signal_range(vec::Union{if_field_t, tr_field_t}) = begin
    my_str = ""
    for i in vec.size
        my_str *= (i > 1) ? ("[$(i-1):0] ") : ("")
    end
    return my_str
end

get_signal_dim(vec::Union{if_field_t, tr_field_t}) = begin
    my_str = ""
    for i in vec.size
        my_str *= (i > 1) ? (" [$(i)]") : ("")
    end
    return my_str
end

gen_line_if_signal(vec::if_field_t, tabs; end_of_line=";") = begin
    if vec.type in packed_types
        return "$(tabs)$(vec.type) $(get_signal_range(vec))$(vec.field_name)$(end_of_line)\n"
    else
        return "$(tabs)$(vec.type) $(vec.field_name)$(get_signal_dim(vec))$(end_of_line)\n"
    end
end

check_for_params(prefix_name) = begin
    do_flag = false
    hierarchical = false
    if prefix_name in uvc_names
        if get_uvc_cfg_fld(prefix_name, :uvc_has_params)
            do_flag = true
            if !get_uvc_cfg_fld(prefix_name, :use_env_params)
                hierarchical = true
            end
        end
    elseif prefix_name == dut_name*"_env" && env_has_params
        do_flag = true
    end
    return do_flag, hierarchical
end

get_uvc_params_prefix(prefix_name) = begin
    if prefix_name in uvc_names && get_uvc_cfg_fld(prefix_name, :uvc_has_params)
        if get_uvc_cfg_fld(prefix_name, :use_env_params)
            params_prefix = dut_name*"_env"
        else
            params_prefix = prefix_name
        end
    elseif prefix_name == dut_name
        params_prefix = dut_name*"_env"
    else
        params_prefix = ""
    end
    return params_prefix
end

get_param_declaration(prefix_name, tabs) = begin
    do_flag, hierarchical = check_for_params(prefix_name)
    my_str = ""
    if do_flag
        my_str *= "#(\n"
        my_str *= "$(tabs)parameter $(prefix_name)_params_t $(prefix_name)_params = '0\n"
        my_str *= ") "
    end
    return my_str
end

get_param_declaration_w_seq_item(prefix_name, tabs) = begin
    do_flag, hierarchical = check_for_params(prefix_name)
    my_str = ""
    if do_flag
        my_str *= """
        #(
        $(tabs)parameter type seq_item_t = uvm_sequence_item,
        $(tabs)parameter $(prefix_name)_params_t $(prefix_name)_params = '0
        ) """
    end
    return my_str
end

get_param_conn(prefix_name, tabs) = begin
    do_flag, hierarchical = check_for_params(prefix_name)
    if do_flag
        my_str = "#(\n$(tabs)    .$(prefix_name)_params($(prefix_name)_params)\n$(tabs)) "
    else
        my_str = ""
    end
    return my_str
end

get_param_conn_env(prefix_name, tabs) = begin
    do_flag, hierarchical = check_for_params(prefix_name)
    if do_flag
        if hierarchical
            my_str = "#(\n$(tabs)    .$(prefix_name)_params($(dut_name)_env_params.$(prefix_name)_params)\n$(tabs)) "
        else
            my_str = "#(\n$(tabs)    .$(prefix_name)_params($(prefix_name)_params)\n$(tabs)) "
        end
    else
        my_str = ""
    end
    return my_str
end

get_param_conn_w_seq_item(prefix_name, tabs) = begin
    do_flag, hierarchical = check_for_params(prefix_name)
    params_prefix = get_uvc_params_prefix(prefix_name)
    if do_flag
        tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
        my_str = """
        #(
        $(tabs)    .seq_item_t($(prefix_name)_$(tr_name)_t),
        $(tabs)    .$(params_prefix)_params($(params_prefix)_params)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end

get_param_conn_w_seq_item_env(prefix_name, tabs) = begin
    do_flag, hierarchical = check_for_params(prefix_name)
    params_prefix = get_uvc_params_prefix(prefix_name)
    if do_flag
        tr_name = get_uvc_cfg_fld(prefix_name, :class_names)["transaction"]
        my_str = """
        #(
        $(tabs)    .seq_item_t($(prefix_name)_$(tr_name)_t),
        """
        if hierarchical
            my_str *= """
            $(tabs)    .$(params_prefix)_params($(dut_name)_env_params.$(params_prefix)_params)
            """
        else
            my_str *= """
            $(tabs)    .$(params_prefix)_params($(params_prefix)_params)
            """
        end
        my_str *= """
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end

get_param_conn_w_seq_item2(prefix_name, tabs) = begin
    do_flag, hierarchical = check_for_params(prefix_name)
    if do_flag
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
    # do_flag, hierarchical = check_for_params(prefix_name)
    if env_has_params
        my_str = """
        #(
        $( gen_long_str(uvc_names, "$(tabs)    ", gen_line_seq_item_t_conn)[1:end-1] )
        $(tabs)    .$(dut_name)_env_params($(dut_name)_env_params)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end

gen_lines_tdefs_w_param(params_prefix, name, tabs) = begin
    my_str = "$(tabs)typedef $(name) $(get_param_conn(params_prefix, tabs))$(name)_t;\n"
    return my_str
end

gen_lines_tdefs_w_param_env(params_prefix, name, tabs) = begin
    my_str = "$(tabs)typedef $(name) $(get_param_conn_env(params_prefix, tabs))$(name)_t;\n"
    return my_str
end

gen_lines_tdefs_w_param_w_seq_item(name, uvc_name, tabs) = begin
    my_str = "$(tabs)typedef $(name) $(get_param_conn_w_seq_item(uvc_name, tabs))$(name)_t;\n"
    return my_str
end

gen_lines_tdefs_w_param_w_seq_item_env(name, uvc_name, tabs) = begin
    my_str = "$(tabs)typedef $(name) $(get_param_conn_w_seq_item_env(uvc_name, tabs))$(name)_t;\n"
    return my_str
end

gen_lines_tdefs_w_param_w_seq_item2(params_prefix, name, tabs) = begin
    my_str = "$(tabs)typedef $(name) $(get_param_conn_w_seq_item2(params_prefix, tabs))$(name)_t;\n"
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

gen_line_param_assign(param_vec::sv_params_t, tabs) = begin
    my_str = "$(tabs)$(param_vec.name): $(param_vec.default_val),\n"
    return my_str
end

get_vsqr_param_declaration(tabs) = begin
    my_str = ""
    if env_has_params
        gen_line(param_vec, tabs) = "$(tabs)$(param_vec.name): $(param_vec.default_val),\n"
        my_str *= """
        #(
        $( gen_long_str(uvc_names, tabs, gen_line_seq_item_t_decl)[1:end-1] )
        $(tabs)parameter $(dut_name)_env_params_t $(dut_name)_env_params = '0
        ) """
    end
    return my_str
end

get_vsqr_param_conn(tabs) = begin
    if env_has_params
        my_str = """
        #(
        $( gen_long_str(uvc_names, tabs*"    ", gen_line_seq_item_t_conn)[1:end-1] )
        $(tabs)    .$(dut_name)_env_params($(dut_name)_env_params)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end

gen_if_signals(tabs, func) = begin
    str = ""
    uvc_names_ = uvc_names
    if using_this_clknrst
        uvc_names_ = filter(x -> x!= clknrst_name, uvc_names)
    end
    for uvc_name in uvc_names_
        if_sigs_vec = get_uvc_cfg_fld(uvc_name, :if_sigs_vec)
        str *= "\n$(tabs)// Signals from $(uvc_name)'s interface - begin\n"
        gen_line(signal_vec, tabs) = func(signal_vec, uvc_name, tabs)
        str *= gen_long_str(if_sigs_vec, tabs*"    ", gen_line)
        str = (uvc_name == uvc_names_[end]) ? str[1:end-2]*"\n" : str
        str *= "$(tabs)// Signals from $(uvc_name)'s interface - end\n"
    end
    return str
end

