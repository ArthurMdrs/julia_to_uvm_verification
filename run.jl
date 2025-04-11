import YAML, StructTypes, ArgParse

cwd = pwd()

include_jl(file) = begin
    if isfile(file)
        include(file)
    else
        error("File not found: $file")
    end
end

function parse_command_line()
    settings = ArgParse.ArgParseSettings()
    ArgParse.@add_arg_table! settings begin
        "-c", "--user_config"
            help = "Specify a user configuration file (.jl)"
            arg_type = String
            default = "$(cwd)/user_config.jl"
        "-u", "--uvc_config"
            help = "Specify a UVC configuration file (.yaml)"
            arg_type = String
            default = "$(cwd)/uvc_config.yaml"
        "-v", "--verbose"
            help = "Print more messages"
            action = :store_true
        "-t", "--debug_time"
            help = "Print elapsed time messages"
            action = :store_true
    end

    return ArgParse.parse_args(ARGS, settings)
end

elapsed_time_array = Dict()

println("You are using the Julia to UVM generator!")

# Check for arguments
time_now = time_ns()
parsed_args = parse_command_line()
verbose = parsed_args["verbose"]
debug_elapsed_time = parsed_args["debug_time"]
if verbose
    println("Parsed Arguments: ")
    for (arg, val) in parsed_args
        println("    $(rpad(arg, 12)) => $(val)")
    end
end
elapsed_time_array["arg_parse"] = (time_ns() - time_now) / 1e9

# Set paths
time_now = time_ns()
user_config_file = parsed_args["user_config"]
uvc_config_file = parsed_args["uvc_config"]
src_path = "$(cwd)/src"
global_config_file = "$(cwd)/global_definitions.jl"
generated_files_dir = "$(cwd)/generated_files"
# tb_top_dir = "$(generated_files_dir)/test_top"
tb_top_dir = generated_files_dir
tests_dir = "$(tb_top_dir)/tests"
sequences_dir = "$(tb_top_dir)/sequences"
env_dir = "$(tb_top_dir)/env"
agents_dir = "$(tb_top_dir)/agents"
rtl_dir = "$(tb_top_dir)/rtl"
elapsed_time_array["set_paths"] = (time_ns() - time_now) / 1e9

#######################################################################################################################

time_now = time_ns()

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

elapsed_time_array["include_setup"] = (time_ns() - time_now) / 1e9

#######################################################################################################################

# Set fields for use in later functions

time_now = time_ns()

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
has_parameters = get_usr_cfg_fld(:has_parameters)
params_vec = get_usr_cfg_fld(:params_vec)
config_inst_convention = get_usr_cfg_fld(:config_inst_convention)
class_names = get_usr_cfg_fld(:class_names)
gen_tdefs_pkg = get_usr_cfg_fld(:gen_tdefs_pkg)
vif_in_config = get_usr_cfg_fld(:vif_in_config)
pass_config_thru_db = get_usr_cfg_fld(:pass_config_thru_db)
reset_mechanism = get_usr_cfg_fld(:reset_mechanism)

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
# debug_elapsed_time = get_usr_cfg_fld(:debug_elapsed_time)

elapsed_time_array["set_configs"] = (time_ns() - time_now) / 1e9

#######################################################################################################################

# Load UVC configuration
time_now = time_ns()
if verbose
    println("Loading UVC configuration from $(uvc_config_file).")
end
uvc_yaml_obj = YAML.load_file(uvc_config_file; dicttype=Dict{Symbol,Any})
elapsed_time_array["load_yaml"] = (time_ns() - time_now) / 1e9

time_now = time_ns()
uvc_config_dict = Dict()
for x in uvc_yaml_obj
    if !haskey(x, :uvc) || x[:uvc] == nothing
        my_str = "UVC name is not defined for the following UVC:\n"
        for (key, value) in x
            my_str *= "  $(key): $(value)\n"
        end
        error(my_str)
    end
    uvc_config_dict[x[:uvc]] = StructTypes.constructfrom(uvc_config_t, x)
    for y in fieldnames(uvc_config_t)
        if y == :class_names
            usn = get_uvc_cfg_fld(x[:uvc], :use_short_names)
            if !(isdefined(uvc_config_dict[x[:uvc]], :class_names))
                uvc_config_dict[x[:uvc]].class_names = usn ? short_names_dict : long_names_dict
                if verbose
                    println("Using default class name dictionary for UVC $(x[:uvc]).")
                end
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
elapsed_time_array["build_config_dict"] = (time_ns() - time_now) / 1e9

time_now = time_ns()
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
elapsed_time_array["build_clknrst_config"] = (time_ns() - time_now) / 1e9

time_now = time_ns()
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
elapsed_time_array["check_uvcs"] = (time_ns() - time_now) / 1e9

#######################################################################################################################

time_now = time_ns()

# Codes for generating the UVC
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

# Codes for generating stub DUT
include_jl("$(src_path)/gen_stub_codes.jl")

# Codes for generating stub env, its components and the test library
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

elapsed_time_array["include_codes"] = (time_ns() - time_now) / 1e9

# Set up the output folder
output_file_setup(generated_files_dir; reset_folder=reset_generated_files_folder)

# Run generation functions
if verbose && run_uvc_gen
    println("Running UVC generation.")
end
elapsed_time_array["gen_uvc" ] = @elapsed uvc_files_gen()
if verbose && run_stub_gen
    println("Running stub generation.")
end
elapsed_time_array["gen_stub"] = @elapsed stub_gen();
if verbose && run_env_gen
    println("Running env generation.")
end
elapsed_time_array["gen_env" ] = @elapsed env_gen();
if verbose && run_test_gen
    println("Running test generation.")
end
elapsed_time_array["gen_test"] = @elapsed test_gen();
if verbose && run_top_gen
    println("Running top generation.")
end
elapsed_time_array["gen_top" ] = @elapsed top_gen();
if verbose && run_sim_args_gen
    println("Running command line arguments generation.")
end
elapsed_time_array["gen_args"] = @elapsed sim_args_gen();

if debug_elapsed_time
    println("Elapsed times:")
    for (key, value) in sort(collect(elapsed_time_array))
        println("    $(rpad(key, 20)) => $(value)")
    end
end
