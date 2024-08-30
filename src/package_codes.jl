# ***********************************
# Package Codes!!!!!
# ***********************************
# This uses a struct found in global_vectors.jl that may
# be overwritten in UVC_parameters/(UVC name)_parameters.jl
# ***********************************
gen_line_include(file_name, tabs) = "$(tabs)`include \"$(file_name).sv\"\n"

vector_to_pattern(prefix_name) = begin
    vec_out = []
    # pkg_includes=["transaction", "sequencer", "sequence_lib", "monitor", "driver", "coverage", "agent"]
    for class_symbol in fieldnames(typeof(pkg_classes))
        class_name = String(class_symbol)
        # if getfield(pkg_classes, class_symbol) == true && class_name in pkg_includes
        if getfield(pkg_classes, class_symbol) == true
            if use_short_names == true
                class_name = short_names_dict[class_name]
            end
            push!(vec_out, prefix_name*"_"*class_name)
        end
    end
    return vec_out
end

gen_tdefs_pkg_base(prefix_name, vec_in) = begin
    vec = vector_to_pattern(prefix_name)
    return """
        package $(prefix_name)_tdefs_pkg;

            typedef enum bit {
                $(uppercase(prefix_name))_COV_ENABLE , 
                $(uppercase(prefix_name))_COV_DISABLE
            } $(prefix_name)_cov_enable_enum;
            
        endpackage: $(prefix_name)_tdefs_pkg
        """
end

gen_pkg_base(prefix_name, vec_in) = begin
    vec = vector_to_pattern(prefix_name)
    if_name = use_short_names ? short_names_dict["interface"] : "interface"
    return """
        package $(prefix_name)_pkg;

            import uvm_pkg::*;
            `include "uvm_macros.svh"
            
            import $(prefix_name)_tdefs_pkg::*;

            typedef virtual interface $(prefix_name)_$(if_name) $(prefix_name)_vif;

        $(gen_long_str(vec, "    ", gen_line_include))
        endpackage: $(prefix_name)_pkg
        """
end
# ****************************************************************