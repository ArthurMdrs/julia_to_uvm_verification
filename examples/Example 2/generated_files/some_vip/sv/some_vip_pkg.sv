package some_vip_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef uvm_config_db#(virtual interface some_vip_if) some_vip_vif_config;
    typedef virtual interface some_vip_if some_vip_vif;

    `include "some_vip_packet.sv"
    `include "some_vip_sequence_lib.sv"
    `include "some_vip_monitor.sv"
    `include "some_vip_sequencer.sv"
    `include "some_vip_driver.sv"
    `include "some_vip_agent.sv"

endpackage: some_vip_pkg
