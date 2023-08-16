# The function below will be used in many files, so we
# will declare it here to avoid repeating code
gen_long_str(vec, tabs, line_gen_func) = begin
    str_aux = ""
    for x in vec
        str_aux *= line_gen_func(x, tabs)
    end
    return str_aux
end

# Codes for generating the UVC
include("code_generate_functions/packet_codes.jl")
include("code_generate_functions/sequence_lib_codes.jl")
include("code_generate_functions/sequencer_codes.jl")
include("code_generate_functions/driver_codes.jl")
include("code_generate_functions/monitor_codes.jl")
include("code_generate_functions/agent_codes.jl")
include("code_generate_functions/package_codes.jl")
include("code_generate_functions/gen_uvc_codes.jl")

# Codes for generating stub interface and DUT
include("code_generate_functions/interface_codes.jl")
include("code_generate_functions/gen_stub_codes.jl")

# Codes for generating test library example
include("code_generate_functions/gen_tests_codes.jl")

# Codes for generating top level module
include("code_generate_functions/gen_top_codes.jl")

# Run generation functions
vip_files_gen();
stub_gen();
test_gen();
top_gen();
