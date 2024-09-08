# ***********************************
# run.f Codes!!!!!
# ***********************************
# Form of the vector to generate the run.f:
#  uvc1_name | uvc2_name | ...
# 
# E.g.:
# stub_if_names = ["uvc_test"]
# 
# This vector comes from the file code_generate_parameters.jl
# ***********************************

gen_uvc_include(uvc_name, tabs) = begin
    cwd = pwd()
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    if_name = use_short_names ? short_names_dict["interface"] : "interface"
    return """
    // $(uppercase(uvc_name)) UVC
    $(tabs)-incdir ../$(uvc_name)/sv
    $(tabs)../$(uvc_name)/sv/$(uvc_name)_pkg.sv
    $(tabs)../$(uvc_name)/sv/$(uvc_name)_$(if_name).sv

    """
end
    
sim_args_gen() = (!run_sim_args_gen) ? "" : begin
    if !(simulator in supported_simulators)
        error("Invalid simulator: $simulator. Expected of of: \n$supported_simulators")
    end
    output_file_setup("generated_files/test_top"; reset_folder=false)
    if simulator == "xrun"
        write_file("generated_files/test_top/xrun_args.f", gen_xrun_args_base())
    elseif simulator == "dsim"
        write_file("generated_files/test_top/dsim_args.f", gen_dsim_args_base())
    end
end

common_args() = begin
    my_str = """
        +UVM_VERBOSITY=UVM_HIGH
        +UVM_NO_RELNOTES
        //+UVM_TESTNAME=random_test
        
    """
    if gen_clknrst
        my_str *= """
        // CLKNRST UVC
            -incdir ../clknrst/sv
            ../clknrst/sv/clknrst_pkg.sv
            ../clknrst/sv/clknrst_if.sv
            
        """
    end
    my_str *= """
    $( gen_long_str(stub_if_names, "    ", gen_uvc_include)[1:end-1] )
    // Stub env
        -incdir .
        ./stub_pkg.sv
    
    // RTL
        ../rtl/stub.sv

    // Top level
        top.sv
    """
    return my_str
end

gen_xrun_args_base() = begin 
    my_str = """
    // xrun options
        -timescale 1ns/1ps
        -access +rwc
        //-gui
        -coverage all
        -covoverwrite
        //+SVSEED=random

    // UVM options
        -uvmhome CDNS-1.2
    """
    my_str *= common_args()
    return my_str
end

gen_dsim_args_base() = begin 
    my_str = """
    // dsim options
        -timescale 1ns/1ps
        +acc
        -waves dump.mxd
        -code-cov a
        //-sv_seed random

    // UVM options
        -uvm 1.2
    """
    my_str *= common_args()
    return my_str
end

# ****************************************************************
