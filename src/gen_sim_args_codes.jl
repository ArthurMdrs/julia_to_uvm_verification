# ***********************************
# run.f Codes
# ***********************************
# Creates a file with arguments to run a simulation
# ***********************************

gen_uvc_include(uvc_name, tabs) = begin
    if_name = get_uvc_cfg_fld(uvc_name, :class_names)["interface"]
    my_str = """
    // $(lowercase(uvc_name)) agent
    $(tabs)-incdir $(agents_dir)/$(uvc_name)
    $(tabs)-incdir $(sequences_dir)/$(uvc_name)
    """
    if get_uvc_cfg_fld(uvc_name, :uvc_has_params) && !get_uvc_cfg_fld(uvc_name, :use_env_params)
        my_str *= "$(tabs)$(agents_dir)/$(uvc_name)/$(uvc_name)_params_pkg.sv\n"
    end
    if get_uvc_cfg_fld(uvc_name, :gen_tdefs_pkg)
        my_str *= "$(tabs)$(agents_dir)/$(uvc_name)/$(uvc_name)_tdefs_pkg.sv\n"
    end
    my_str *= """
    $(tabs)$(agents_dir)/$(uvc_name)/$(uvc_name)_pkg.sv
    $(tabs)$(agents_dir)/$(uvc_name)/$(uvc_name)_$(if_name).sv

    """
    return my_str
end
gen_line_agent_lst(uvc_name, tabs) = begin
    my_str = """
    $(tabs)-f $(srclists_dir)/agents/$(uvc_name).lst
    """
end
    
sim_args_gen() = begin
    if run_sim_args_gen == true
        # if !(simulator in supported_simulators) # This check is done in run.jl now
        #     error("Invalid simulator: $simulator. Expected of of: \n$supported_simulators")
        # end
        output_file_setup("$(tb_top_dir)"; reset_folder=false)
        output_file_setup("$(srclists_dir)")
        output_file_setup("$(srclists_dir)/agents")
        for uvc_name in uvc_names
            write_file("$(srclists_dir)/agents/$(uvc_name).lst", gen_uvc_include(uvc_name, "    "))
        end
        write_file("$(srclists_dir)/$(dut_name)_env.lst", gen_env_srclist())
        write_file("$(srclists_dir)/$(dut_name)_tb.lst", gen_tb_srclist())
        if simulator == "xrun"
            write_file("$(tb_top_dir)/xrun_args.f", gen_xrun_args_base())
        elseif simulator == "dsim"
            write_file("$(tb_top_dir)/dsim_args.f", gen_dsim_args_base())
        end
    end
end

gen_env_srclist() = begin
    my_str = ""
    
    agts_bef_env_params = []
    agts_aft_env_params = []
    for uvc_name in uvc_names
        if get_uvc_cfg_fld(uvc_name, :uvc_has_params) && !get_uvc_cfg_fld(uvc_name, :use_env_params)
            push!(agts_bef_env_params, uvc_name)
        else
            push!(agts_aft_env_params, uvc_name)
        end
    end
    
    if size(agts_bef_env_params)[1] > 0
        my_str *= """
        // Agents
        $( gen_long_str(agts_bef_env_params, "    ", gen_line_agent_lst)[1:end-1] )
        
        """
    end
    
    if env_has_params
        my_str *= """
        // Parameters package
            $(env_dir)/$(dut_name)_env_params_pkg.sv
            
        """
    end
    
    if size(agts_aft_env_params)[1] > 0
        my_str *= """
        // Agents
        $( gen_long_str(agts_aft_env_params, "    ", gen_line_agent_lst)[1:end-1] )
        
        """
    end
    
    my_str *= """
    // Env
        -incdir $(env_dir)
        -incdir $(sequences_dir)
        -incdir $(tests_dir)
        $(env_dir)/$(dut_name)_env_pkg.sv
    """
    return my_str
end

gen_tb_srclist() = begin
    my_str = """
    // Env
        -f $(srclists_dir)/$(dut_name)_env.lst
    
    // RTL
        $(rtl_dir)/$(dut_name).sv

    // Top level
        $(tb_top_dir)/$(dut_name)_tb_pkg.sv
        $(tb_top_dir)/$(dut_name)_tb_top.sv
    """
    return my_str
end

common_args() = begin
    my_str = """
        +UVM_VERBOSITY=UVM_HIGH
        +UVM_NO_RELNOTES
        //+UVM_TESTNAME=random_test
        
        -f $(srclists_dir)/$(dut_name)_tb.lst
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
