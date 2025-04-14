# ***********************************
# Package Codes
# ***********************************
# Creates the UVC package
# ***********************************
gen_line_include(file_name, tabs) = "$(tabs)`include \"$(file_name).sv\"\n"

vector_to_pattern(prefix_name) = begin
    vec_out = []
    for class_symbol in fieldnames(typeof(pkg_classes))
        class_name = String(class_symbol)
        if String(class_symbol) == "coverage"
            if get_uvc_cfg_fld(prefix_name, :agent_has_coverage) == true
                class_name = get_uvc_cfg_fld(prefix_name, :class_names)[class_name]
                push!(vec_out, prefix_name*"_"*class_name)
            end
        elseif getfield(pkg_classes, class_symbol) == true
            class_name = get_uvc_cfg_fld(prefix_name, :class_names)[class_name]
            push!(vec_out, prefix_name*"_"*class_name)
        end
    end
    return vec_out
end

gen_tdefs_base(prefix_name) = begin
    vec = params_vec
    my_str = """
    package $(prefix_name)_tdefs_pkg;
        
    """
    if get_uvc_cfg_fld(prefix_name, :uvc_has_params)
        if get_uvc_cfg_fld(prefix_name, :use_env_params)
            my_str *= """
                import $(dut_name)_env_params_pkg::*;
                
            """
        else
            my_str *= """
                import $(prefix_name)_params_pkg::*;
                
            """
        end
    end
    my_str *= """
        // Define your typedefs here!
        typedef enum int {
            SOME_VAL,
            OTHER_VAL
        } type_name_t;
        
    """
    my_str *= """
    endpackage : $(prefix_name)_tdefs_pkg
    """
    return my_str
end

gen_pkg(prefix_name, type::uvc_class_type) = begin
    vec = vector_to_pattern(prefix_name)
    my_str = """
    package $(prefix_name)_pkg;
        
        import uvm_pkg::*;
        `include "uvm_macros.svh"
        
    """
    
    if get_uvc_cfg_fld(prefix_name, :uvc_has_params)
        if get_uvc_cfg_fld(prefix_name, :use_env_params)
            my_str *= """
                import $(dut_name)_env_params_pkg::*;
                
            """
        else
            my_str *= """
                import $(prefix_name)_params_pkg::*;
                
            """
        end
    end
    
    if get_uvc_cfg_fld(prefix_name, :gen_tdefs_pkg) == true
        my_str *= """
            import $(prefix_name)_tdefs_pkg::*;
            
        """
    end
    
    my_str *= """
    $( gen_long_str(vec, "    ", gen_line_include)[1:end-1] )
        
        `include "$(prefix_name)_base_sequence.sv"
    """
    
    if type == normal::uvc_class_type
        my_str *= """
            `include "$(prefix_name)_random_seq.sv"
        """
    elseif type == clknrst::uvc_class_type
        seq_vec = []
        for x in clknrst_actions_vec
            push!(seq_vec, prefix_name*"_"*x*"_seq")
        end
        my_str *= """
        $( gen_long_str(seq_vec, "    ", gen_line_include)[1:end-1] )
            `include "$(prefix_name)_reset_and_start_clk_seq.sv"
        """
    end
        
    my_str *= """
        
    endpackage : $(prefix_name)_pkg
    """
    return my_str
end

gen_clknrst_tdefs(prefix_name) = begin
    vec = vector_to_pattern(prefix_name)
    my_str = """
    package $(prefix_name)_tdefs_pkg;
        
    """
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

gen_pkg_base(prefix_name) = gen_pkg(prefix_name, normal::uvc_class_type)
gen_clknrst_pkg(prefix_name) = gen_pkg(prefix_name, clknrst::uvc_class_type)

# ****************************************************************

gen_uvc_params_pkg(prefix_name) = begin
    params_vec = get_uvc_cfg_fld(prefix_name, :params_vec)
    my_str = """
    package $(prefix_name)_params_pkg;
        
        typedef struct packed {
    $( gen_long_str(params_vec, "        ", gen_line_param)[1:end-1] )
        } $(prefix_name)_params_t;
        
    """
    
    my_str *= """
        localparam $(prefix_name)_params_t $(prefix_name)_params = '{
    $( gen_long_str(params_vec, "        ", gen_line_param_assign)[1:end-2] )
        };
        
    """
    
    my_str *= """
    endpackage : $(prefix_name)_params_pkg
    """
    return my_str
end

# ****************************************************************