# ***********************************
# Tests Codes!!!!!
# ***********************************
# Form of the vector to generate the tests:
#  vip1_name | vip2_name | ...
# 
# E.g.:
# stub_if_names = ["vip_test"]
# 
# This vector comes from the file code_generate_parameters.jl
# ***********************************

gen_line_VIP_instance(vip_name, tabs) = 
    """$(tabs)$(vip_name)_agent agent_$(vip_name);\n"""
gen_line_VIP_creation(vip_name, tabs) = 
    """$(tabs)agent_$(vip_name) = $(vip_name)_agent::type_id::create("agent_$(vip_name)", this);\n"""
gen_line_sequences_config(vip_name, tabs) = 
    """$(tabs)uvm_config_wrapper::set(this, "agent_$(vip_name).sequencer.run_phase", "default_sequence", $(vip_name)_random_seq::get_type());\n"""

test_gen() = (!run_test_gen) ? "" : begin
    output_file_setup("generated_files/test_top")
    write_file("generated_files/test_top/tests.sv", gen_test_base())
end

gen_test_base() = """
    class base_test extends uvm_test;

        `uvm_component_utils(base_test)

        // VIPs instances - begin
    $( gen_long_str(stub_if_names, "    ", gen_line_VIP_instance) )    // VIPs instances - end

        uvm_objection obj;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);

            // Edit to set some agent to passive
            // uvm_config_db#(int)::set(this, "some_vip", "is_active", UVM_PASSIVE);

            // Edit to disable some agent's coverage
            // uvm_config_db#(int)::set(this, "some_vip", "cov_control", COV_DISABLE);

            // VIPs creation - begin
    $( gen_long_str(stub_if_names, "        ", gen_line_VIP_creation) )        // VIPs creation - end

            `uvm_info("BASE TEST", "Build phase running", UVM_HIGH)
            uvm_config_db#(int)::set(this, "*", "recording_detail", 1);
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
            // Override packet types, eg:
            //      first_type_name::type_id::set_type_override(second_type_name::get_type());
            super.build_phase(phase);

            // Random sequences config - begin
    $( gen_long_str(stub_if_names, "        ", gen_line_sequences_config) )        // Random sequences config - end
            
        endfunction: build_phase

    endclass: random_test

    //==============================================================//
    """
# ****************************************************************
