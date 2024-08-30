# Struct used to define package and class generation vectors
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
    classes_t() = new(true,true,true,true,true,true,true,true,true,true,true)
    classes_t(a,b,c,d,e,f,g,h,i,j,k) = new(a,b,c,d,e,f,g,h,i,j,k)
end
# Obs.: classes are included in the package in the order they are declared above, so don't change it

# Vector that defines which classes will be included in the package
pkg_classes = classes_t(true,true,true,true,true,true,true,true,false,false,false)
# Vector that defines which classes will be generated as files
gen_classes = classes_t()

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
)