# ***********************************
# Env Codes!!!!!
# ***********************************
# Form of the vector to generate the tests:
#  uvc1_name | uvc2_name | ...
# 
# E.g.:
# stub_if_names = ["uvc_test"]
# 
# This vector comes from the file code_generate_parameters.jl
# ***********************************

gen_line_uvc_instance(uvc_name, tabs) = 
"""$(tabs)$(uvc_name)_agent agent_$(uvc_name);\n"""
gen_line_uvc_creation(uvc_name, tabs) = 
"""$(tabs)agent_$(uvc_name) = $(uvc_name)_agent::type_id::create("agent_$(uvc_name)", this);\n"""

gen_line_sequences_config(uvc_name, tabs) = 
"""$(tabs)uvm_config_wrapper::set(this, "agent_$(uvc_name).sequencer.run_phase", "default_sequence", $(uvc_name)_random_seq::get_type());\n"""

gen_line_cfg_instance(uvc_name, tabs) = begin
cwd = pwd()
include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
cfg_name = use_short_names ? short_names_dict["config"] : "config"
restore_config()
return """$(tabs)$(uvc_name)_$(cfg_name) cfg_$(uvc_name);\n"""
end
gen_line_cfg_utils(uvc_name, tabs) = begin
return "$(tabs)`uvm_field_object(cfg_$(uvc_name), UVM_ALL_ON)\n"
end
gen_line_cfg_creation(uvc_name, tabs) = begin
cwd = pwd()
include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
cfg_name = use_short_names ? short_names_dict["config"] : "config"
restore_config()
return """
$(tabs)cfg_$(uvc_name) = $(uvc_name)_$(cfg_name)::type_id::create("cfg_$(uvc_name)");
$(tabs)uvm_config_db#($(uvc_name)_$(cfg_name))::set(.cntxt(this), .inst_name("agent_$(uvc_name)"), .field_name("cfg"), .value(cfg_$(uvc_name)));
"""
end

gen_line_vif_instance(uvc_name, tabs) = begin
return """$(tabs)$(uvc_name)_vif vif_$(uvc_name);\n"""
end
gen_vif_config_db_lines(uvc_name, tabs) = begin
return """
    $(tabs)if(uvm_config_db#($(uvc_name)_vif)::get(.cntxt(this), .inst_name(""), .field_name("vif_$(uvc_name)"), .value(vif_$(uvc_name))))
    $(tabs)    `uvm_info("BASE TEST", "$(uppercase(uvc_name)) virtual interface was successfully set!", UVM_MEDIUM)
    $(tabs)else
    $(tabs)    `uvm_fatal("BASE TEST", "No interface was set!")
    $(tabs)uvm_config_db#($(uvc_name)_vif)::set(.cntxt(this), .inst_name("agent_$(uvc_name)"), .field_name("vif"), .value(vif_$(uvc_name)));
    """
end

env_gen() = (!run_env_gen) ? "" : begin
    output_file_setup("generated_files/test_top"; reset_folder=false)
    write_file("generated_files/test_top/stub_env.sv", gen_env_base())
    write_file("generated_files/test_top/stub_pkg.sv", gen_env_pkg())
end

gen_env_base() = begin 
    cfg_name = use_short_names ? short_names_dict["config"     ] : "config"
    my_str = """
    class stub_env extends uvm_env;

        // Config objects - begin
    """
    my_str *= gen_clknrst ? "    clknrst_cfg cfg_clknrst;\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "    ", gen_line_cfg_instance)[1:end-1] )
        // Config objects - end
        
        `uvm_component_utils_begin(base_test)
    """
    my_str *= gen_clknrst ? "        `uvm_field_object(cfg_clknrst, UVM_ALL_ON)\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_line_cfg_utils)[1:end-1] )
        `uvm_component_utils_end

        // Interfaces instances - begin
    """
    my_str *= gen_clknrst ? "    clknrst_vif vif_clknrst;\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "    ", gen_line_vif_instance)[1:end-1] )
        // Interfaces instances - end

        // UVCs instances - begin
    """
    my_str *= gen_clknrst ? "    clknrst_agent agent_clknrst;\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "    ", gen_line_uvc_instance)[1:end-1] )
        // UVCs instances - end 

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);

    """
    my_str *= gen_clknrst ? "        cfg_clknrst = clknrst_cfg::type_id::create(\"cfg_clknrst\");\n" : ""
    my_str *= gen_clknrst ? "        uvm_config_db#(clknrst_cfg)::set(.cntxt(this), .inst_name(\"agent_clknrst\"), .field_name(\"cfg\"), .value(cfg_clknrst));\n" : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_line_cfg_creation) )
            // Edit to set some agent to passive
            // cfg_$(stub_if_names[1]).is_active = UVM_PASSIVE;

            // Edit to disable some agent's coverage
            // cfg_$(stub_if_names[1]).cov_control = $(uppercase(stub_if_names[1]))_COV_DISABLE;

    """
    my_str *= gen_clknrst ? gen_vif_config_db_lines("clknrst", "        ") : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_vif_config_db_lines) )
            // UVCs creation - begin
    """
    my_str *= gen_clknrst ? gen_line_uvc_creation("clknrst", "        ") : ""
    my_str *= """
    $( gen_long_str(stub_if_names, "        ", gen_line_uvc_creation) )        // UVCs creation - end

            `uvm_info("STUB ENV", "Build phase running", UVM_HIGH)
        endfunction

        // function void connect_phase (uvm_phase phase);
        //     super.connect_phase(phase);
        //     
        //     vsequencer.sequencer_uvc1 = agent_uvc1.sequencer;
        //     vsequencer.sequencer_uvc2 = agent_uvc2.sequencer;
        //     vsequencer.sequencer_uvc3 = agent_uvc3.sequencer;
        // endfunction: connect_phase

    endclass: stub_env
    """
    return my_str
end

gen_env_pkg() = begin
    return """
    package stub_pkg;

        import uvm_pkg::*;
        `include "uvm_macros.svh"
        
        import stub_tdefs_pkg::*;
    $( gen_long_str(stub_if_names, "    ", gen_line_import)[1:end-1] )

        // `include "stub_vseqr.sv"
        // `include "stub_vseq_lib.sv"
        `include "stub_env.sv"
        
        `include "tests.sv"
                
    endpackage: stub_pkg
    """
end

# ****************************************************************