# Struct used to define package and class generation vectors - Do NOT edit
mutable struct classes_t
    config::Bool
    transaction::Bool
    sequencer::Bool
    sequence_lib::Bool
    monitor::Bool
    driver::Bool
    coverage::Bool
    agent::Bool
    tdefs_pkg::Bool
    pkg::Bool
    interface::Bool
    # params_pkg::Bool
    classes_t() = new(true,true,true,true,true,true,true,true,true,true,true)
    classes_t(a,b,c,d,e,f,g,h,i,j,k) = new(a,b,c,d,e,f,g,h,i,j,k)
end
# Obs.: classes are included in the package in the order they are declared above, so don't change it

# Vector that defines which classes will be included in the package
pkg_classes = classes_t(true,true,true,true,true,true,true,true,false,false,false)
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
    "config" => "cfg",
    "agent" => "agent",
    "tdefs_pkg" => "tdefs_pkg",
    "pkg" => "pkg",
    "interface" => "if",
    "vsequencer" => "vsqr",
    "sequence" => "seq",
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
)

# Default settings - Do NOT edit
reset_generated_files_folder = true
uvc_names = []
stub_if_names = uvc_names
dut_name = ""
gen_clknrst = true
run_uvc_gen = true
run_stub_gen = true
run_env_gen = true
run_test_gen = true
run_top_gen = true
run_sim_args_gen = true
simulator = "xrun"
clock_name = "clk"
reset_name = "rst_n"
rst_is_negedge_sensitive = true
use_short_names = true
has_paramaters = false
agent_has_coverage = false
cfg_name = use_short_names ? short_names_dict["config"] : long_names_dict["config"]
config_inst_convention = "m_$(cfg_name)"

debug_function_time = false

supported_simulators = ["xrun", "dsim"]
