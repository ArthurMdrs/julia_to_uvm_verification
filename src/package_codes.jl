# ***********************************
# Package Codes
# ***********************************
# Creates the UVC package
# This uses a struct found in global_vectors.jl that may
# be overwritten in UVC_parameters/(UVC name)_parameters.jl
# ***********************************
gen_line_include(file_name, tabs) = "$(tabs)`include \"$(file_name).sv\"\n"

vector_to_pattern(prefix_name) = begin
    vec_out = []
    for class_symbol in fieldnames(typeof(pkg_classes))
        class_name = String(class_symbol)
        if String(class_symbol) == "coverage"
            if agent_has_coverage == true
                class_name = use_short_names ? short_names_dict[class_name] : long_names_dict[class_name]
                push!(vec_out, prefix_name*"_"*class_name)
            end
        elseif getfield(pkg_classes, class_symbol) == true
            class_name = use_short_names ? short_names_dict[class_name] : long_names_dict[class_name]
            push!(vec_out, prefix_name*"_"*class_name)
        end
    end
    return vec_out
end

gen_tdefs_base(prefix_name, vec) = begin
    vec = params_vec
    my_str = """
    package $(prefix_name)_tdefs_pkg;
        
    """
    if agent_has_coverage
        my_str *= """
            typedef enum bit {
                $(uppercase(prefix_name))_COV_ENABLE , 
                $(uppercase(prefix_name))_COV_DISABLE
            } $(prefix_name)_cov_enable_enum_t;
            
        """
    else
        my_str *= """
            typedef enum bit {
                $(uppercase(prefix_name))_SOME_VAL, 
                $(uppercase(prefix_name))_OTHER_VAL
            } $(prefix_name)_some_tdef_t;
            
        """
    end 
    my_str *= """
    endpackage: $(prefix_name)_tdefs_pkg
    """
    return my_str
end

gen_pkg_base(prefix_name, vec) = begin
    vec = vector_to_pattern(prefix_name)
    if_name = use_short_names ? short_names_dict["interface"] : long_names_dict["interface"]
    my_str = """
        package $(prefix_name)_pkg;
            
            import uvm_pkg::*;
            `include "uvm_macros.svh"
        """
        
        if has_paramaters
            my_str *= """
                
                import $(dut_name)_params_pkg::*;
            """
        end
        
        my_str *= """
            
            //`include "$(prefix_name)_tdefs.sv"
            import $(prefix_name)_tdefs_pkg::*;
            
        $(gen_line_vif_typedef(prefix_name, "    ")[1:end-1])
            
        $(gen_long_str(vec, "    ", gen_line_include))
        endpackage: $(prefix_name)_pkg
        """
    return my_str
end

gen_clknrst_tdefs() = begin
    prefix_name = "clknrst";
    vec = vector_to_pattern(prefix_name)
    my_str = """
    package $(prefix_name)_tdefs_pkg;
        
    """
    if agent_has_coverage
        my_str *= """
            typedef enum bit {
                $(uppercase(prefix_name))_COV_ENABLE , 
                $(uppercase(prefix_name))_COV_DISABLE
            } $(prefix_name)_cov_enable_enum_t;
            
        """
    end
    my_str *= """
        typedef enum bit [1:0] {
            $(uppercase(prefix_name))_ACTION_START_CLK   ,
            $(uppercase(prefix_name))_ACTION_STOP_CLK    ,
            $(uppercase(prefix_name))_ACTION_ASSERT_RESET,
            $(uppercase(prefix_name))_ACTION_RESTART_CLK
        } $(prefix_name)_action_enum_t;
        
        typedef enum bit [1:0] {
            $(uppercase(prefix_name))_INITIAL_VALUE_0,
            $(uppercase(prefix_name))_INITIAL_VALUE_1,
            $(uppercase(prefix_name))_INITIAL_VALUE_X
        } $(prefix_name)_init_val_enum_t;
        
    endpackage : $(prefix_name)_tdefs_pkg
    """
    return my_str
end

gen_clknrst_pkg() = gen_pkg_base("clknrst", [])

# ****************************************************************