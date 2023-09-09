# ***********************************
# run.f Codes!!!!!
# ***********************************
# Form of the vector to generate the run.f:
#  vip1_name | vip2_name | ...
# 
# E.g.:
# stub_if_names = ["vip_test"]
# 
# This vector comes from the file code_generate_parameters.jl
# ***********************************

gen_vip_include(vip_name, tabs) = """
    // $(uppercase(vip_name)) UVC
    $(tabs)-incdir ../$(vip_name)/sv
    $(tabs)../$(vip_name)/sv/$(vip_name)_pkg.sv
    $(tabs)../$(vip_name)/sv/$(vip_name)_if.sv
    """
    
run_file_gen() = (!run_run_file_gen) ? "" : begin
    output_file_setup("generated_files/test_top"; reset_folder=false)
    write_file("generated_files/test_top/run.f", gen_run_file_base())
end

gen_run_file_base() = """
    // xrun options
        -timescale 1ns/1ns
        -access +rwc
        //-gui
        //+SVSEED=random

    // UVM options
        -uvmhome \$UVMHOME
        +UVM_VERBOSITY=UVM_HIGH
        +UVM_NO_RELNOTES
        //+UVM_TESTNAME=random_test

    $( gen_long_str(stub_if_names, "    ", gen_vip_include) )
    // RTL
        ../rtl/stub.sv

    // Top level
        top.sv
    """
