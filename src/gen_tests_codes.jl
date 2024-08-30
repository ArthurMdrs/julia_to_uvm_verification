# ***********************************
# Tests Codes!!!!!
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
    return """$(tabs)$(uvc_name)_$(cfg_name) cfg_$(uvc_name);\n"""
end
gen_line_cfg_utils(uvc_name, tabs) = begin
    cwd = pwd()
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    cfg_name = use_short_names ? short_names_dict["config"] : "config"
    return "$(tabs)`uvm_field_object(cfg_$(uvc_name), UVM_ALL_ON)\n"
end
gen_line_cfg_creation(uvc_name, tabs) = begin
    cwd = pwd()
    include_jl("$(cwd)/UVC_parameters/$(uvc_name)_parameters.jl")
    cfg_name = use_short_names ? short_names_dict["config"] : "config"
    return """
    $(tabs)cfg_$(uvc_name) = $(uvc_name)_$(cfg_name)::type_id::create("cfg_$(uvc_name)");
    $(tabs)uvm_config_db#($(uvc_name)_$(cfg_name))::set(.cntxt(this), .inst_name("agent_$(uvc_name)"), .field_name("cfg"), .value(cfg_$(uvc_name)));
    """
end

test_gen() = (!run_test_gen) ? "" : begin
    output_file_setup("generated_files/test_top")
    write_file("generated_files/test_top/tests.sv", gen_test_base())
end

gen_test_base() = begin 
    cfg_name = use_short_names ? short_names_dict["config"     ] : "config"
    return """
    class base_test extends uvm_test;

        // Config objects - begin
    $( gen_long_str(stub_if_names, "    ", gen_line_cfg_instance) )    // Config objects - end
        
        `uvm_component_utils_begin(base_test)
    $( gen_long_str(stub_if_names, "        ", gen_line_cfg_utils) )    `uvm_component_utils_end

        // UVCs instances - begin
    $( gen_long_str(stub_if_names, "    ", gen_line_uvc_instance) )    // UVCs instances - end

        uvm_objection obj;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);

    $( gen_long_str(stub_if_names, "        ", gen_line_cfg_creation) )
            // Edit to set some agent to passive
            // uvm_config_db#(int)::set(this, "agent_$(stub_if_names[1])", "is_active", UVM_PASSIVE);
            // uvm_config_db#(int)::set(.cntxt(this), .inst_name("agent_$(stub_if_names[1])"), .field_name("is_active"), .value(UVM_PASSIVE));

            // Edit to disable some agent's coverage
            // uvm_config_db#(int)::set(this, "agent_$(stub_if_names[1])", "cov_control", $(uppercase(stub_if_names[1]))_COV_DISABLE);
            // uvm_config_db#(int)::set(.cntxt(this), .inst_name("agent_$(stub_if_names[1])"), .field_name("cov_control"), .value($(uppercase(stub_if_names[1]))_COV_DISABLE));

            // UVCs creation - begin
    $( gen_long_str(stub_if_names, "        ", gen_line_uvc_creation) )        // UVCs creation - end

            `uvm_info("BASE TEST", "Build phase running", UVM_HIGH)
            uvm_config_db#(int)::set(.cntxt(this), .inst_name("*"), .field_name("recording_detail"), .value(1));
        endfunction

        function void end_of_elaboration_phase (uvm_phase phase);
            super.end_of_elaboration_phase(phase);
            uvm_top.print_topology();
        endfunction

        function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            check_config_usage();
        endfunction

        virtual task run_phase(uvm_phase phase);
            super.run_phase(phase);
            obj = phase.get_objection();
            obj.set_drain_time(this, 200ns);
        endtask: run_phase

    endclass: base_test

    //==============================================================//

    class random_test extends base_test;

        `uvm_component_utils(random_test)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction: new

        function void build_phase(uvm_phase phase);
            // Override transaction types, eg:
            //      original_type_name::type_id::set_type_override(override_type_name::get_type());
            //      set_type_override_by_type (original_type::get_type(), override_type::get_type());
            //      set_inst_override_by_type (original_type::get_type(), override_type::get_type(), "full_inst_path");
            super.build_phase(phase);

            // Random sequences config - begin
    $( gen_long_str(stub_if_names, "        ", gen_line_sequences_config) )        // Random sequences config - end
            
        endfunction: build_phase

    endclass: random_test

    //==============================================================//
    """
    end
# ****************************************************************
