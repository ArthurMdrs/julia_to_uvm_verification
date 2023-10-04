# Struct used to define package and class generation vectors
mutable struct classes_t
    packet::Bool
    sequence_lib::Bool
    monitor::Bool
    sequencer::Bool
    driver::Bool
    coverage::Bool
    agent::Bool
    pkg::Bool
    interface::Bool
    classes_t() = new(true,true,true,true,true,true,true,true,true)
    classes_t(a,b,c,d,e,f,g,h,i) = new(a,b,c,d,e,f,g,h,i)
    classes_t(a,b,c,d,e,f,g) = new(a,b,c,d,e,f,g,false,false)
end

# Vector that defines which classes will be included in the package
pkg_classes = classes_t()
# Vector that defines which classes will be generated as files
gen_classes = classes_t()
