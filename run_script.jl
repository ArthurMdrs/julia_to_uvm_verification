cwd = pwd()
src_path = cwd * "/src"

include_jl(file) = begin
    if isfile(file)
        include(file)
    else
        error("File not found: $file")
    end
end


# Check for arguments
if length(ARGS) >= 1
    gen_params_file = ARGS[1]
else
    gen_params_file = "$(cwd)/code_generate_parameters.jl"
end
println("Using parameters file $(gen_params_file)")


# Common functions
include_jl("$(src_path)/common.jl")

# Global parameters
include_jl(gen_params_file)
include_jl("./global_vectors.jl")

# Codes for generating the UVC
include_jl("$(src_path)/transaction_codes.jl")
include_jl("$(src_path)/sequence_lib_codes.jl")
include_jl("$(src_path)/sequencer_codes.jl")
include_jl("$(src_path)/driver_codes.jl")
include_jl("$(src_path)/monitor_codes.jl")
include_jl("$(src_path)/coverage_codes.jl")
include_jl("$(src_path)/agent_codes.jl")
include_jl("$(src_path)/package_codes.jl")
include_jl("$(src_path)/gen_uvc_codes.jl")
include_jl("$(src_path)/interface_codes.jl")

# Codes for generating stub DUT
include_jl("$(src_path)/gen_stub_codes.jl")

# Codes for generating test library example
include_jl("$(src_path)/gen_tests_codes.jl")

# Codes for generating top level module
include_jl("$(src_path)/gen_top_codes.jl")

# Codes for generating run.f file
include_jl("$(src_path)/gen_run_file_codes.jl")


# Set up the output folder
output_file_setup("$(cwd)/generated_files"; reset_folder=reset_generated_files_folder)

# Run generation functions
vip_files_gen();
stub_gen();
test_gen();
top_gen();
run_file_gen();
