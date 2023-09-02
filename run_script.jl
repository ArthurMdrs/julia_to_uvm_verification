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

# Global parameters
include("code_generate_parameters.jl")
include("./global_vectors.jl")

# Codes for generating the UVC
include("code_generate_functions/packet_codes.jl")
include("code_generate_functions/sequence_lib_codes.jl")
include("code_generate_functions/sequencer_codes.jl")
include("code_generate_functions/driver_codes.jl")
include("code_generate_functions/monitor_codes.jl")
include("code_generate_functions/agent_codes.jl")
include("code_generate_functions/package_codes.jl")
include("code_generate_functions/gen_uvc_codes.jl")

# Codes for generating stub DUT and interface
include("code_generate_functions/interface_codes.jl")
include("code_generate_functions/gen_stub_codes.jl")

# Codes for generating test library example
include("code_generate_functions/gen_tests_codes.jl")

# Codes for generating top level module
include("code_generate_functions/gen_top_codes.jl")

# Codes for generating run.f file
include("code_generate_functions/gen_run_file_codes.jl")

# Set up the output folder
output_file_setup("generated_files"; reset_folder=reset_generated_files_folder)

# Run generation functions
vip_files_gen();
stub_gen();
test_gen();
top_gen();
run_file_gen();
