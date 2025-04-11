# Struct used to define package and class generation vectors - Do NOT edit
mutable struct classes_t
    config::Bool
    transaction::Bool
    sequencer::Bool
    # sequence_lib::Bool
    monitor::Bool
    driver::Bool
    coverage::Bool
    agent::Bool
    tdefs_pkg::Bool
    pkg::Bool
    interface::Bool
    # params_pkg::Bool
    # classes_t() = new(true,true,true,true,true,true,true,true,true,true,true)
    # classes_t(a,b,c,d,e,f,g,h,i,j,k) = new(a,b,c,d,e,f,g,h,i,j,k)
    classes_t() = new(true,true,true,true,true,true,true,true,true,true)
    classes_t(a,b,c,d,e,f,g,h,i,j) = new(a,b,c,d,e,f,g,h,i,j)
end
# Obs.: classes are included in the package in the order they are declared above, so don't change it

# Vector that defines which classes will be included in the package
# pkg_classes = classes_t(true,true,true,true,true,true,true,true,false,false,false)
pkg_classes = classes_t(true,true,true,true,true,true,true,false,false,false)
# Vector that defines which classes will be generated as files
gen_classes = classes_t()



# Dictionaries used to define class names - You can edit
short_names_dict = Dict(
    "transaction" => "tr",
    "sequence_lib" => "seq_lib",
    "monitor" => "mon",
    "sequencer" => "sqr",
    "driver" => "drv",
    "coverage" => "cov",
    "config" => "config",
    "agent" => "agent",
    "tdefs_pkg" => "tdefs_pkg",
    "pkg" => "pkg",
    "interface" => "if",
    "vsequencer" => "vsqr",
    "sequence" => "seq",
    "scoreboard" => "sb",
    "ref_model" => "refmod",
)
long_names_dict = Dict(
    "transaction" => "transaction",
    "sequence_lib" => "sequence_lib",
    "monitor" => "monitor",
    "sequencer" => "sequencer",
    "driver" => "driver",
    "coverage" => "coverage",
    "config" => "config",
    "agent" => "agent",
    "tdefs_pkg" => "tdefs_pkg",
    "pkg" => "pkg",
    "interface" => "interface",
    "vsequencer" => "vsequencer",
    "sequence" => "sequence",
    "scoreboard" => "scoreboard",
    "ref_model" => "ref_model",
)

# Default settings - Do NOT edit

mutable struct sv_params_t
    type::String
    name::String
    default_val::String
    sv_params_t() = new()
    sv_params_t(a, b, c) = new(a, b, c)
end

@enum reset_mechanism_t begin
    run_phase_reset = 0
    reset_phase_reset = 1
end

mutable struct config_t
    # Delete generated files folder before running
    reset_generated_files_folder::Union{Bool, Nothing}
    # UVCs and env generation
    uvc_names::Vector{String}
    dut_name::String
    gen_clknrst::Union{Bool, Nothing}
    gen_scoreboard::Union{Bool, Nothing}
    gen_refmod::Union{Bool, Nothing}
    use_short_names::Union{Bool, Nothing}
    agent_has_coverage::Union{Bool, Nothing}
    agent_has_tdefs_pkg::Union{Bool, Nothing}
    env_has_coverage::Union{Bool, Nothing}
    has_parameters::Union{Bool, Nothing}
    params_vec::Vector{sv_params_t}
    # params_vec::Vector{Vector{String}}
    config_inst_convention::String
    class_names::Dict{String, String}
    gen_tdefs_pkg::Union{Bool, Nothing}
    vif_in_config::Union{Bool, Nothing}
    pass_config_thru_db::Union{Bool, Nothing}
    reset_mechanism::reset_mechanism_t
    # Clock and reset info
    clock_name::String
    reset_name::String
    rst_is_negedge_sensitive::Union{Bool, Nothing}
    # Control what files to generate
    run_uvc_gen::Union{Bool, Nothing}
    run_stub_gen::Union{Bool, Nothing}
    run_env_gen::Union{Bool, Nothing}
    run_test_gen::Union{Bool, Nothing}
    run_top_gen::Union{Bool, Nothing}
    run_sim_args_gen::Union{Bool, Nothing}
    # Others
    simulator::String
    # Debug
    # debug_elapsed_time::Union{Bool, Nothing}
    config_t() = new()
end
# StructTypes.StructType(::Type{config_t}) = StructTypes.Mutable()

# fields_config_t = fieldnames(config_t)

global_config = config_t()
user_config = config_t()

# Delete generated files folder before running
global_config.reset_generated_files_folder = true

# UVCs and env generation
global_config.uvc_names = []
global_config.dut_name = ""
global_config.gen_clknrst = false
clknrst_name = "clknrst"
using_this_clknrst = false
clknrst_actions_vec = ["start_clk", "stop_clk", "restart_clk", "assert_reset"]
global_config.gen_scoreboard = false
global_config.gen_refmod = false
global_config.use_short_names = true
global_config.agent_has_coverage = false
global_config.agent_has_tdefs_pkg = false
global_config.env_has_coverage = false
global_config.has_parameters = false
global_config.params_vec = []
param_len = 3
# cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
# config_inst_convention = "m_$(cfg_name)"
global_config.config_inst_convention = "m_config"
global_config.class_names = short_names_dict
global_config.gen_tdefs_pkg = false
global_config.vif_in_config = true
global_config.pass_config_thru_db = true
global_config.reset_mechanism = run_phase_reset

# Clock and reset info
global_config.clock_name = "clk"
global_config.reset_name = "rst_n"
global_config.rst_is_negedge_sensitive = true

# Control what files to generate
global_config.run_uvc_gen = true
global_config.run_stub_gen = true
global_config.run_env_gen = true
global_config.run_test_gen = true
global_config.run_top_gen = true
global_config.run_sim_args_gen = true

# Others
global_config.simulator = "xrun"
supported_simulators = ["xrun", "dsim"]

# Debug
# global_config.debug_elapsed_time = true



mutable struct tr_field_t
    field_name::String
    type::String
    range::String
    is_rand::Union{Bool, Nothing}
    tr_field_t() = new()
end
StructTypes.StructType(::Type{tr_field_t}) = StructTypes.Mutable()

mutable struct if_field_t
    field_name::String
    type::String
    range::String
    is_output::Union{Bool, Nothing}
    if_field_t() = new()
end
StructTypes.StructType(::Type{if_field_t}) = StructTypes.Mutable()

mutable struct uvc_config_t
    uvc::String
    rst_is_negedge_sensitive::Union{Bool, Nothing}
    clock_name::String
    reset_name::String
    use_short_names::Union{Bool, Nothing}
    agent_has_coverage::Union{Bool, Nothing}
    gen_tdefs_pkg::Union{Bool, Nothing}
    vif_in_config::Union{Bool, Nothing}
    tr_props_vec::Vector{tr_field_t}
    if_sigs_vec::Vector{if_field_t}
    class_names::Dict{String, String}
    uvc_config_t() = new()
end
StructTypes.StructType(::Type{uvc_config_t}) = StructTypes.Mutable()


@enum uvc_class_type begin
    normal = 0
    clknrst = 1
end
