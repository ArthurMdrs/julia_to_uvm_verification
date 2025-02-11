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

restore_config() = begin
    include_jl("./global_vectors.jl")
    include_jl(gen_params_file)
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
    if uvc_name == "clknrst"
        if_name  = use_short_names ? short_names_dict["interface"] : long_names_dict["interface"]
    else
        include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
        if_name  = use_short_names ? short_names_dict["interface"] : long_names_dict["interface"]
        restore_config()
    end
    my_str = "$(tabs)typedef virtual interface $(uvc_name)_$(if_name) $(get_param_conn(tabs))$(uvc_name)_vif_t;\n"
    return my_str
end
    

get_param_declaration(params_vec, prefix_name, tabs) = begin
    my_str = ""
    if has_paramaters
        my_str *="#(parameter $(prefix_name)_params_t $(prefix_name)_params = '{\n"
        gen_line(param_vec, tabs) = "$(tabs)$(param_vec[2]): $(param_vec[3]),\n"
        my_str *= gen_long_str(params_vec, tabs*"    ", gen_line)[1:end-2]
        my_str *= " }\n) "
    end
    return my_str
end

get_param_declaration_w_seq_item(params_vec, prefix_name, tabs) = begin
    my_str = ""
    if has_paramaters
        gen_line(param_vec, tabs) = "$(tabs)$(param_vec[2]): $(param_vec[3]),\n"
        my_str *= """
        #(
        $(tabs)parameter type seq_item_t = uvm_sequence_item,
        $(tabs)parameter $(prefix_name)_params_t $(prefix_name)_params = '{
        $(gen_long_str(params_vec, tabs*"    ", gen_line)[1:end-2])
        $(tabs)}
        ) """
    end
    return my_str
end

get_param_conn(tabs) = begin
    if has_paramaters
        my_str = "#(\n$(tabs)    .$(dut_name)_params($(dut_name)_params)\n$(tabs)) "
    else
        my_str = ""
    end
    return my_str
end

get_param_conn_w_seq_item(uvc_name, tabs) = begin
    if has_paramaters
        tr_name  = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
        my_str = """
        #(
        $(tabs)    .seq_item_t($(uvc_name)_$(tr_name)_t),
        $(tabs)    .$(dut_name)_params($(dut_name)_params)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end

get_param_conn_w_seq_item2(tabs) = begin
    if has_paramaters
        my_str = """
        #(
        $(tabs)    .seq_item_t(seq_item_t),
        $(tabs)    .$(dut_name)_params($(dut_name)_params)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end

gen_lines_tdefs_w_param(name, tabs) = begin
    my_str = "$(tabs)typedef $(name) $(get_param_conn(tabs))$(name)_t;\n"
    return my_str
end

gen_lines_tdefs_w_param_w_seq_item(name, uvc_name, tabs) = begin
    my_str = "$(tabs)typedef $(name) $(get_param_conn_w_seq_item(uvc_name, tabs))$(name)_t;\n"
    return my_str
end

gen_lines_tdefs_w_param_w_seq_item2(name, tabs) = begin
    my_str = "$(tabs)typedef $(name) $(get_param_conn_w_seq_item2(tabs))$(name)_t;\n"
    return my_str
end

gen_lines_tdefs_wo_param(name, tabs) = begin
    my_str  = "$(tabs)typedef $(name) $(name)_t;\n\n"
    return my_str
end

gen_line_cfg_instance(uvc_name, tabs) = begin
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
    restore_config()
    return """$(tabs)$(uvc_name)_$(cfg_name)_t m_$(uvc_name)_$(cfg_name);\n"""
end

gen_line_seq_item_t_conn(uvc_name, tabs) = begin
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    tr_name  = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
    restore_config()
    my_str = "$(tabs).$(uvc_name)_$(tr_name)_t($(uvc_name)_$(tr_name)_t),\n"
    return my_str
end

gen_vsqr_param_conn(tabs) = begin
    tr_name = use_short_names ? short_names_dict["transaction"] : long_names_dict["transaction"]
    if has_paramaters
        my_str = """
        #($(gen_clknrst ? "\n$(tabs)    .clknrst_$(tr_name)_t(clknrst_$(tr_name)_t)," : "")
        $( gen_long_str(stub_if_names, "$(tabs)    ", gen_line_seq_item_t_conn)[1:end-1] )
        $(tabs)    .$(dut_name)_params($(dut_name)_params)
        $(tabs)) """
    else
        my_str = ""
    end
    return my_str
end


