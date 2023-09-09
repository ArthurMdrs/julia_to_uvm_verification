# ***********************************
# Package Codes!!!!!
# ***********************************
# Form of the vector to generate the pkg:
#  class_file_1 | class_file_2 | ...
# 
# E.g.:
# pkg_vec = ["agent", "driver", "monitor", "sequence_lib"]
#
# This vector comes from the file global_vectors.jl, but it may 
# be overwritten in VIP_parameters/(VIP name)_parameters.jl
# ***********************************
priority_dict = Dict(
    "packet" => 1,
    "sequence_lib" => 2,
    "monitor" => 3,
    "sequencer" => 3,
    "driver" => 3,
    "agent" => 4
)
gen_line_include(file_name, tabs) = "$(tabs)`include \"$(file_name).sv\"\n"

vector_to_pattern(prefix_name, vec_in) = begin
    vec_aux = []
    vec_out = []
    for x in vec_in
        push!(vec_aux, [x, priority_dict[lowercase(x)]])
    end

    int_aux = 1
    file_cont = 0
    while (file_cont < length(vec_aux))
        for x in vec_aux
            if x[2] == int_aux 
                push!(vec_out, prefix_name*"_"*lowercase(x[1]))
                file_cont += 1
            end
        end
        int_aux += 1
    end
    return vec_out
end

gen_pkg_base(prefix_name, vec_in) = begin
    vec = vector_to_pattern(prefix_name, vec_in)
    return """
        package $(prefix_name)_pkg;

            import uvm_pkg::*;
            `include "uvm_macros.svh"

            typedef uvm_config_db#(virtual interface $(prefix_name)_if) $(prefix_name)_vif_config;
            typedef virtual interface $(prefix_name)_if $(prefix_name)_vif;

        $(gen_long_str(vec, "    ", gen_line_include))
        endpackage: $(prefix_name)_pkg
        """
    end
# ****************************************************************