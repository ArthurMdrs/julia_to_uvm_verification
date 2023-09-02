package another_vip_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef uvm_config_db#(virtual interface another_vip_if) another_vip_vif_config;
    typedef virtual interface another_vip_if another_vip_vif;

    `include "another_vip_packet.sv"
    `include "another_vip_sequence_lib.sv"
    `include "another_vip_sequencer.sv"
    `include "another_vip_monitor.sv"
    `include "another_vip_driver.sv"
    `include "another_vip_agent.sv"

endpackage: another_vip_pkg
