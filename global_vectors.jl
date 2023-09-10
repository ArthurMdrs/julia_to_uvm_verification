# DEPRECATED CODE BEGIN
# Vector that defines which classes will be included in the package
# pkg_vec = ["sequence_lib", "sequencer", "packet", "agent", "monitor", "driver"]
# Vector that defines which classes will be generated as files
# vec_classes = ["sequence_lib", "sequencer", "packet", "agent", "monitor", "driver", "pkg", "if"]
# DEPRECATED CODE END

# Struct used to define package and class generation vectors
mutable struct classes_t
    packet::Bool
    sequence_lib::Bool
    monitor::Bool
    sequencer::Bool
    driver::Bool
    agent::Bool
    pkg::Bool
    interface::Bool
    classes_t() = new(true,true,true,true,true,true,true,true)
    classes_t(a,b,c,d,e,f,g,h) = new(a,b,c,d,e,f,g,h)
    classes_t(a,b,c,d,e,f) = new(a,b,c,d,e,f,false,false)
end

# Vector that defines which classes will be included in the package
pkg_classes = classes_t()
# Vector that defines which classes will be generated as files
gen_classes = classes_t()
