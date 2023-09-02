# ***********************************
# VIP Gen Codes!!!!!
# ***********************************
# São usados os vetores presentes em global_vectors.jl
# E/ou em VIP_parameters/(VIP name)_parameters.jl
# ***********************************

function_dict = Dict()

open_file(dir) = open(str_aux->read(str_aux, String), dir)

gen_files(vec_classes, vip_name) = begin
    for class_name in vec_classes
        # The vector below works like this:
        # vec_aux["class_name"] = [gen_function, vector]
        vec_aux = function_dict[uppercase(class_name)]
        write_file("generated_files/"*vip_name*"/sv/$(vip_name)_$(class_name).sv", 
                    vec_aux[1](vip_name, vec_aux[2]))
    end
end

vip_files_gen() = (!run_vip_gen) ? "" : begin
    for vip_name in vip_names
        include("./global_vectors.jl")
        include("./VIP_parameters/"*vip_name*"_parameters.jl")

        function_dict[uppercase("packet")] = [gen_packet_base, packet_vec]
        function_dict[uppercase("pkg")] = [gen_pkg_base, pkg_vec]
        function_dict[uppercase("sequencer")] = [gen_sequencer_base,[]]
        function_dict[uppercase("sequence_lib")] = [gen_sequence_lib_base,[]]
        function_dict[uppercase("if")] = [gen_if_base, if_vec]
        function_dict[uppercase("driver")] = [gen_driver_base, if_vec[1:2]]
        function_dict[uppercase("monitor")] = [gen_monitor_base, if_vec[1:2]]
        function_dict[uppercase("agent")] = [gen_agent_base,[]]

        output_file_setup("generated_files/"*vip_name)
        output_file_setup("generated_files/"*vip_name*"/sv")
        output_file_setup("generated_files/"*vip_name*"/parameter_folder")

        gen_files(vec_classes, vip_name)
        write_file("generated_files/"*vip_name*"/parameter_folder/"*vip_name*"_parameters.jl", 
                    open_file("VIP_parameters/"*vip_name*"_parameters.jl"))
        
    end
end
