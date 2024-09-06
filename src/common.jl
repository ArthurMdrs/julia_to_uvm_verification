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
