# ***********************************
# UVC Gen Codes!!!!!
# ***********************************
# This uses the vectors found in global_vectors.jl
# And/or in UVC_parameters/(UVC name)_parameters.jl
# ***********************************

function_dict = Dict()

open_file(dir) = open(str_aux->read(str_aux, String), dir)

gen_files(uvc_name) = begin
    for class_symbol in fieldnames(typeof(gen_classes))
        class_name = String(class_symbol)
        if getfield(gen_classes, class_symbol) == true
            # The vector below works like this
            # vec_aux["class_name"] = [gen_function, vector]
            vec_aux = function_dict[uppercase(class_name)]
            push!(vec_aux, use_short_names)
            if use_short_names == true
                class_name = short_names_dict[class_name]
            end
            write_file("generated_files/$(uvc_name)/sv/$(uvc_name)_$(class_name).sv", 
                        vec_aux[1](uvc_name, vec_aux[2]))
        end
    end
end

gen_clknrst_files() = begin
    cwd = pwd()
    uvc_name = "clknrst"
    global use_short_names = true
    function_dict[uppercase("transaction" )] = [gen_clknrst_tr          , []]
    function_dict[uppercase("tdefs_pkg"   )] = [gen_clknrst_tdefs_pkg   , []]
    function_dict[uppercase("pkg"         )] = [gen_clknrst_pkg         , []]
    function_dict[uppercase("sequencer"   )] = [gen_clknrst_sequencer   , []]
    function_dict[uppercase("sequence_lib")] = [gen_clknrst_sequence_lib, []]
    function_dict[uppercase("interface"   )] = [gen_clknrst_if          , []]
    function_dict[uppercase("driver"      )] = [gen_clknrst_driver      , []]
    function_dict[uppercase("monitor"     )] = [gen_clknrst_monitor     , []]
    function_dict[uppercase("agent"       )] = [gen_clknrst_agent       , []]
    function_dict[uppercase("coverage"    )] = [gen_clknrst_coverage    , []]
    function_dict[uppercase("config"      )] = [gen_clknrst_config      , []]

    output_file_setup("$(cwd)/generated_files/$(uvc_name)")
    output_file_setup("$(cwd)/generated_files/$(uvc_name)/sv")
    output_file_setup("$(cwd)/generated_files/$(uvc_name)/parameter_folder")
    
    for class_symbol in fieldnames(typeof(gen_classes))
        class_name = String(class_symbol)
        vec_aux = function_dict[uppercase(class_name)]
        push!(vec_aux, use_short_names)
        if use_short_names == true
            class_name = short_names_dict[class_name]
        end
        write_file("generated_files/$(uvc_name)/sv/$(uvc_name)_$(class_name).sv", vec_aux[1]())
    end
end

uvc_files_gen() = (!run_uvc_gen) ? "" : begin
    cwd = pwd()
    for uvc_name in uvc_names
        include_jl("$(cwd)/global_vectors.jl")
        include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
        
        function_dict[uppercase("transaction" )] = [gen_tr_base          , tr_vec     ]
        function_dict[uppercase("tdefs_pkg"   )] = [gen_tdefs_pkg_base   , []         ]
        function_dict[uppercase("pkg"         )] = [gen_pkg_base         , []         ]
        function_dict[uppercase("sequencer"   )] = [gen_sequencer_base   , []         ]
        function_dict[uppercase("sequence_lib")] = [gen_sequence_lib_base, []         ]
        function_dict[uppercase("interface"   )] = [gen_if_base          , if_vec     ]
        function_dict[uppercase("driver"      )] = [gen_driver_base      , if_vec[1:2]]
        function_dict[uppercase("monitor"     )] = [gen_monitor_base     , if_vec[1:2]]
        function_dict[uppercase("agent"       )] = [gen_agent_base       , []         ]
        function_dict[uppercase("coverage"    )] = [gen_coverage_base    , tr_vec     ]
        function_dict[uppercase("config"      )] = [gen_config_base      , []         ]

        output_file_setup("$(cwd)/generated_files/$(uvc_name)")
        output_file_setup("$(cwd)/generated_files/$(uvc_name)/sv")
        output_file_setup("$(cwd)/generated_files/$(uvc_name)/parameter_folder")

        gen_files(uvc_name)
        write_file("$(cwd)/generated_files/$(uvc_name)/parameter_folder/$(uvc_name)_parameters.jl", 
                    open_file("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl"))
    end
    
    # Generate clock and reset UVC
    if gen_clknrst
        gen_clknrst_files()
    end
    
end
