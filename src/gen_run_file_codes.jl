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
    $(tabs)../$(uvc_name)/sv/$(uvc_name)_tdefs_pkg.sv
    $(tabs)../$(uvc_name)/sv/$(uvc_name)_pkg.sv
    $(tabs)../$(uvc_name)/sv/$(uvc_name)_$(if_name).sv

    """
end
    
run_file_gen() = (!run_run_file_gen) ? "" : begin
    output_file_setup("generated_files/test_top"; reset_folder=false)
    write_file("generated_files/test_top/run.f", gen_run_file_base())
end

gen_run_file_base() = begin 
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
        +UVM_VERBOSITY=UVM_HIGH
        +UVM_NO_RELNOTES
        //+UVM_TESTNAME=random_test
        
    """
    if gen_clknrst
        my_str *= """
        // CLKNRST UVC
            -incdir ../clknrst/sv
            ../clknrst/sv/clknrst_tdefs_pkg.sv
            ../clknrst/sv/clknrst_pkg.sv
            ../clknrst/sv/clknrst_if.sv
            
        """
    end
    my_str *= """
    $( gen_long_str(stub_if_names, "    ", gen_uvc_include) )// RTL
        ../rtl/stub.sv

    // Top level
        top.sv
    """
    return my_str
end
