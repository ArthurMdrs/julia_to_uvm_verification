import YAML, StructTypes

cwd = pwd()

include_jl(file) = begin
    if isfile(file)
        include(file)
    else
        error("File not found: $file")
    end
end


# Check for arguments
if length(ARGS) >= 1
    user_config_file = ARGS[1]
    println("Using user config file $(user_config_file)")
else
    user_config_file = "$(cwd)/user_config.jl"
    println("You can pass a config file as an argument. Using default $(user_config_file)")
end


# Set paths
src_path = "$(cwd)/src"
global_config_file = "$(cwd)/global_definitions.jl"
uvc_config_file = "$(cwd)/uvc_config.yaml"
generated_files_dir = "$(cwd)/generated_files"
# tb_top_dir = "$(generated_files_dir)/test_top"
tb_top_dir = generated_files_dir
tests_dir = "$(tb_top_dir)/tests"
sequences_dir = "$(tb_top_dir)/sequences"
env_dir = "$(tb_top_dir)/env"
agents_dir = "$(tb_top_dir)/agents"
rtl_dir = "$(tb_top_dir)/rtl"

#######################################################################################################################

# Global parameters
include_jl(global_config_file)
# User parameters
include_jl(user_config_file)

# I think it's easier for global and user config to be straight Julia
# global_config = YAML.load_file("global_config.yaml"; dicttype=Dict{Symbol,Any})
# user_config = YAML.load_file("user_config.yaml"; dicttype=Dict{Symbol,Any})

# Common functions
include_jl("$(src_path)/common.jl")

# Check if user configurations are valid
simulator_ = get_usr_cfg_fld(:simulator)
if !(simulator_ in supported_simulators)
    error("Unsupported simulator: $(simulator_). Provide one of: $(supported_simulators)")
end

#######################################################################################################################

# Set fields for use in later functions

# Delete generated files folder before running
reset_generated_files_folder = get_usr_cfg_fld(:reset_generated_files_folder)

# UVCs and env generation
uvc_names = get_usr_cfg_fld(:uvc_names)
dut_name = get_usr_cfg_fld(:dut_name)
gen_clknrst = get_usr_cfg_fld(:gen_clknrst)
gen_scoreboard = get_usr_cfg_fld(:gen_scoreboard)
gen_refmod = get_usr_cfg_fld(:gen_refmod)
use_short_names = get_usr_cfg_fld(:use_short_names)
agent_has_coverage = get_usr_cfg_fld(:agent_has_coverage)
env_has_coverage = get_usr_cfg_fld(:env_has_coverage)
has_paramaters = get_usr_cfg_fld(:has_paramaters)
params_vec = get_usr_cfg_fld(:params_vec)
config_inst_convention = get_usr_cfg_fld(:config_inst_convention)
class_names = get_usr_cfg_fld(:class_names)
gen_tdefs_pkg = get_usr_cfg_fld(:gen_tdefs_pkg)
vif_in_config = get_usr_cfg_fld(:vif_in_config)

# Clock and reset info
clock_name = get_usr_cfg_fld(:clock_name)
reset_name = get_usr_cfg_fld(:reset_name)
rst_is_negedge_sensitive = get_usr_cfg_fld(:rst_is_negedge_sensitive)

# Control what files to generate
run_uvc_gen = get_usr_cfg_fld(:run_uvc_gen)
run_stub_gen = get_usr_cfg_fld(:run_stub_gen)
run_env_gen = get_usr_cfg_fld(:run_env_gen)
run_test_gen = get_usr_cfg_fld(:run_test_gen)
run_top_gen = get_usr_cfg_fld(:run_top_gen)
run_sim_args_gen = get_usr_cfg_fld(:run_sim_args_gen)

# Others
simulator = get_usr_cfg_fld(:simulator)

# Debug
debug_function_time = get_usr_cfg_fld(:debug_function_time)


#######################################################################################################################

# Load UVC configuration
uvc_yaml_obj = YAML.load_file(uvc_config_file; dicttype=Dict{Symbol,Any})

uvc_config_dict = Dict()
for x in uvc_yaml_obj
    uvc_config_dict[x[:uvc]] = StructTypes.constructfrom(uvc_config_t, x)
    for y in fieldnames(uvc_config_t)
        if y == :class_names
            usn = get_uvc_cfg_fld(x[:uvc], :use_short_names)
            if !(isdefined(uvc_config_dict[x[:uvc]], :class_names))
                uvc_config_dict[x[:uvc]].class_names = usn ? short_names_dict : long_names_dict
                println("Using default class name dictionary for UVC.")
            else
                for key in keys(short_names_dict)
                    if !haskey(uvc_config_dict[x[:uvc]].class_names, key)
                        uvc_config_dict[x[:uvc]].class_names[key] = usn ? short_names_dict[key] : long_names_dict[key]
                    end
                end
            end
        elseif !(isdefined(uvc_config_dict[x[:uvc]], y))
            @warn "Field $(y) of UVC is undefined."
        end
    end
    # println(uvc_config_dict[x[:uvc]])
end

if gen_clknrst == true && !haskey(uvc_config_dict, clknrst_name)
    using_this_clknrst = true
    push!(uvc_names, clknrst_name)
    clknrst_config = uvc_config_t()
    clknrst_config.uvc = clknrst_name
    clknrst_config.rst_is_negedge_sensitive = rst_is_negedge_sensitive
    clknrst_config.clock_name = clock_name
    clknrst_config.reset_name = reset_name
    clknrst_config.use_short_names = use_short_names
    clknrst_config.agent_has_coverage = false
    clknrst_config.gen_tdefs_pkg = true
    clknrst_config.vif_in_config = true
    clknrst_config.tr_props_vec = []
    clknrst_config.if_sigs_vec = []
    clknrst_config.class_names = use_short_names ? short_names_dict : long_names_dict
    uvc_config_dict[clknrst_name] = clknrst_config
end

for uvc in uvc_names
    status = false
    for uvc_ in keys(uvc_config_dict)
        if uvc_ == uvc
            status = true
        end
    end
    if !status
        error("No configuration is provided for UVC $(uvc). Please provide its configuration in $(uvc_config_file)")
    end
end

#######################################################################################################################

# # Codes for generating the UVC
include_jl("$(src_path)/config_codes.jl")
include_jl("$(src_path)/transaction_codes.jl")
include_jl("$(src_path)/sequence_lib_codes.jl")
include_jl("$(src_path)/sequencer_codes.jl")
include_jl("$(src_path)/driver_codes.jl")
include_jl("$(src_path)/monitor_codes.jl")
include_jl("$(src_path)/coverage_codes.jl")
include_jl("$(src_path)/agent_codes.jl")
include_jl("$(src_path)/package_codes.jl")
include_jl("$(src_path)/interface_codes.jl")
include_jl("$(src_path)/gen_uvc_codes.jl")

# # Codes for generating stub DUT
include_jl("$(src_path)/gen_stub_codes.jl")

# # Codes for generating stub env, its components and the test library
include_jl("$(src_path)/refmod_codes.jl")
include_jl("$(src_path)/scoreboard_codes.jl")
include_jl("$(src_path)/vsequencer_codes.jl")
include_jl("$(src_path)/vseq_lib_codes.jl")
include_jl("$(src_path)/gen_env_codes.jl")

# Codes for generating the tests
include_jl("$(src_path)/gen_tests_codes.jl")

# Codes for generating top level module
include_jl("$(src_path)/gen_top_codes.jl")

# Codes for generating simulator arguments file
include_jl("$(src_path)/gen_sim_args_codes.jl")


# Set up the output folder
output_file_setup(generated_files_dir; reset_folder=reset_generated_files_folder)

# Run generation functions
elapsed_time_array = Dict()
elapsed_time_array["uvc" ] = @elapsed uvc_files_gen()
elapsed_time_array["stub"] = @elapsed stub_gen();
elapsed_time_array["env" ] = @elapsed env_gen();
elapsed_time_array["test"] = @elapsed test_gen();
elapsed_time_array["top" ] = @elapsed top_gen();
elapsed_time_array["args"] = @elapsed sim_args_gen();

if debug_function_time
    println("Elapsed times:")
    for (key, value) in elapsed_time_array
        println("$(key) => $(value)")
    end
end
