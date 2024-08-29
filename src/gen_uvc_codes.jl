# ***********************************
# VIP Gen Codes!!!!!
# ***********************************
# This uses the vectors found in global_vectors.jl
# And/or in VIP_parameters/(VIP name)_parameters.jl
# ***********************************

function_dict = Dict()

open_file(dir) = open(str_aux->read(str_aux, String), dir)

gen_files(vip_name) = begin
    for class_symbol in fieldnames(typeof(gen_classes))
        class_name = String(class_symbol)
        # if class_name == "interface" 
        #     class_name = "if" 
        # end
        if getfield(gen_classes, class_symbol) == true
            # The vector below works like this
            # vec_aux["class_name"] = [gen_function, vector]
            if use_short_names == true
                class_name = short_names_dict[class_name]
            end
            vec_aux = function_dict[uppercase(class_name)]
            push!(vec_aux, use_short_names)
            # println(vip_name, vec_aux)
            write_file("generated_files/"*vip_name*"/sv/$(vip_name)_$(class_name).sv", 
                        vec_aux[1](vip_name, vec_aux[2]))
        end
    end
end

vip_files_gen() = (!run_vip_gen) ? "" : begin
    cwd = pwd()
    for vip_name in vip_names
        include_jl("$(cwd)/global_vectors.jl")
        include_jl("$(cwd)/VIP_parameters/"*vip_name*"_parameters.jl")
        
        if use_short_names == true
            function_dict[uppercase("tr"       )] = [gen_tr_base          , tr_vec     ]
            function_dict[uppercase("tdefs_pkg")] = [gen_tdefs_pkg_base   , []         ]
            function_dict[uppercase("pkg"      )] = [gen_pkg_base         , []         ]
            function_dict[uppercase("sqr"      )] = [gen_sequencer_base   , []         ]
            function_dict[uppercase("seq_lib"  )] = [gen_sequence_lib_base, []         ]
            function_dict[uppercase("if"       )] = [gen_if_base          , if_vec     ]
            function_dict[uppercase("drv"      )] = [gen_driver_base      , if_vec[1:2]]
            function_dict[uppercase("mon"      )] = [gen_monitor_base     , if_vec[1:2]]
            function_dict[uppercase("agent"    )] = [gen_agent_base       , []         ]
            function_dict[uppercase("cov"      )] = [gen_coverage_base    , tr_vec     ]
        else
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
        end

        output_file_setup("$(cwd)/generated_files/"*vip_name)
        output_file_setup("$(cwd)/generated_files/"*vip_name*"/sv")
        output_file_setup("$(cwd)/generated_files/"*vip_name*"/parameter_folder")

        gen_files(vip_name)
        write_file("$(cwd)/generated_files/"*vip_name*"/parameter_folder/"*vip_name*"_parameters.jl", 
                    open_file("$(cwd)/VIP_parameters/"*vip_name*"_parameters.jl"))
        
    end
end
