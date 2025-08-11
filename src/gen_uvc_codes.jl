# ***********************************
# UVC Gen Codes
# ***********************************
# Creates all UVC files:
# tr, pkgs, sequencer, seq_lib, if, driver, monitor, agent, config
# ***********************************

function_dict = Dict()
function_dict["transaction" ] = gen_tr_base          
function_dict["tdefs_pkg"   ] = gen_tdefs_base       
function_dict["pkg"         ] = gen_pkg_base         
function_dict["sequencer"   ] = gen_sequencer_base   
# function_dict["sequence_lib"] = gen_sequence_lib_base
function_dict["interface"   ] = gen_if_base          
function_dict["driver"      ] = gen_driver_base      
function_dict["monitor"     ] = gen_monitor_base     
function_dict["agent"       ] = gen_agent_base       
function_dict["coverage"    ] = gen_coverage_base    
function_dict["config"      ] = gen_config_base      

clknrst_function_dict = Dict()
clknrst_function_dict["transaction" ] = gen_clknrst_tr          
clknrst_function_dict["tdefs_pkg"   ] = gen_clknrst_tdefs       
clknrst_function_dict["pkg"         ] = gen_clknrst_pkg         
clknrst_function_dict["sequencer"   ] = gen_clknrst_sequencer   
# clknrst_function_dict["sequence_lib"] = gen_clknrst_sequence_lib
clknrst_function_dict["interface"   ] = gen_clknrst_if          
clknrst_function_dict["driver"      ] = gen_clknrst_driver      
clknrst_function_dict["monitor"     ] = gen_clknrst_monitor     
clknrst_function_dict["agent"       ] = gen_clknrst_agent       
clknrst_function_dict["coverage"    ] = gen_clknrst_coverage    
clknrst_function_dict["config"      ] = gen_clknrst_config      

gen_single_file(uvc_name, class_name, function_dict, classes_vec) = begin
    gen_class_func = function_dict[class_name]
    class_name = get_uvc_cfg_fld(uvc_name, :class_names)[class_name]
    if "$(uvc_name)_$(class_name)" in classes_vec
        is_class = true
    else
        is_class = false
    end
    ext = is_class ? class_files_extension : "sv"
    write_file("$(agents_dir)/$(uvc_name)/$(uvc_name)_$(class_name).$(ext)", gen_class_func(uvc_name))
end

gen_files(uvc_name) = begin
    if using_this_clknrst == true && uvc_name == clknrst_name
        function_dict_ = clknrst_function_dict
    else
        function_dict_ = function_dict
    end
    
    classes_vec = vector_to_pattern(uvc_name)
    
    # Generate components
    for class_symbol in fieldnames(typeof(gen_classes))
        class_name = String(class_symbol)
        do_not_gen = true
        if class_name == "coverage"
            if get_uvc_cfg_fld(uvc_name, :agent_has_coverage) == true
                do_not_gen = false
            end
        elseif class_name == "tdefs_pkg"
            if get_uvc_cfg_fld(uvc_name, :gen_tdefs_pkg) == true
                do_not_gen = false
            end
        elseif getfield(gen_classes, class_symbol) == true
            do_not_gen = false
        end
        if do_not_gen == false
            gen_single_file(uvc_name, class_name, function_dict_, classes_vec)
        end
    end
    
    # Generate parameters vector
    if get_uvc_cfg_fld(uvc_name, :uvc_has_params) && !get_uvc_cfg_fld(uvc_name, :use_env_params)
        write_file("$(agents_dir)/$(uvc_name)/$(uvc_name)_params_pkg.sv", gen_uvc_params_pkg(uvc_name))
    end
    
    # Generate sequences
    write_file("$(sequences_dir)/$(uvc_name)/$(uvc_name)_base_seq.$(class_files_extension)", gen_base_seq(uvc_name))
    if using_this_clknrst == true && uvc_name == clknrst_name
        for action in clknrst_actions_vec
            write_file("$(sequences_dir)/$(uvc_name)/$(uvc_name)_$(action)_seq.$(class_files_extension)", gen_clknrst_action_seq(action, uvc_name))
        end
        write_file("$(sequences_dir)/$(uvc_name)/$(uvc_name)_reset_and_start_clk_seq.$(class_files_extension)", gen_clknrst_rst_and_start_clk_seq(uvc_name))
    else
        write_file("$(sequences_dir)/$(uvc_name)/$(uvc_name)_random_seq.$(class_files_extension)", gen_random_seq(uvc_name))
    end
end

uvc_files_gen() = begin
    if run_uvc_gen
        # output_file_setup("$(agents_dir)"; reset_folder=false)
        output_file_setup("$(agents_dir)")
        output_file_setup("$(sequences_dir)"; reset_folder=false)
        uvc_names_iter = ProgressBar(uvc_names)
        ProgressBars.set_description(uvc_names_iter, "Generating UVC files:")
        for uvc_name in uvc_names_iter
            output_file_setup("$(agents_dir)/$(uvc_name)")
            output_file_setup("$(sequences_dir)/$(uvc_name)")
            # output_file_setup("$(agents_dir)/$(uvc_name)/parameter_folder")
            
            gen_files(uvc_name)
        end
    end
end
