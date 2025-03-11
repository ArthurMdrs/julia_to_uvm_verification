# ***********************************
# run.f Codes
# ***********************************
# Creates a file with arguments to run a simulation
# ***********************************

gen_uvc_include(uvc_name, tabs) = begin
    if_name = get_uvc_cfg_fld(uvc_name, :class_names)["interface"]
    my_str = """
    // $(uppercase(uvc_name)) UVC
    $(tabs)-incdir $(agents_dir)/$(uvc_name)
    $(tabs)-incdir $(sequences_dir)/$(uvc_name)
    """
    if get_uvc_cfg_fld(uvc_name, :gen_tdefs_pkg) == true
        my_str *= "$(tabs)$(agents_dir)/$(uvc_name)/$(uvc_name)_tdefs_pkg.sv\n"
    end
    my_str *= """
    $(tabs)$(agents_dir)/$(uvc_name)/$(uvc_name)_pkg.sv
    $(tabs)$(agents_dir)/$(uvc_name)/$(uvc_name)_$(if_name).sv

    """
    return my_str
end
    
sim_args_gen() = begin
    if run_sim_args_gen == true
        # if !(simulator in supported_simulators) # This check is done in run.jl now
        #     error("Invalid simulator: $simulator. Expected of of: \n$supported_simulators")
        # end
        output_file_setup("$(tb_top_dir)"; reset_folder=false)
        if simulator == "xrun"
            write_file("$(tb_top_dir)/xrun_args.f", gen_xrun_args_base())
        elseif simulator == "dsim"
            write_file("$(tb_top_dir)/dsim_args.f", gen_dsim_args_base())
        end
    end
end

common_args() = begin
    my_str = """
        +UVM_VERBOSITY=UVM_HIGH
        +UVM_NO_RELNOTES
        //+UVM_TESTNAME=random_test
        
    """
    if has_paramaters
        my_str *= """
        // Parameters package
            $(env_dir)/$(dut_name)_params_pkg.sv
            
        """
    end
    my_str *= """
    $( gen_long_str(uvc_names, "    ", gen_uvc_include)[1:end-1] )
    // DUT env
        -incdir $(env_dir)
        -incdir $(sequences_dir)
        $(env_dir)/$(dut_name)_env_pkg.sv
    
    // RTL
        $(rtl_dir)/$(dut_name).sv
    
    // Tests
        -incdir $(tests_dir)

    // Top level
        $(tb_top_dir)/$(dut_name)_tb_pkg.sv
        $(tb_top_dir)/$(dut_name)_tb_top.sv
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
