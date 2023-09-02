// xrun options
    -timescale 1ns/1ns
    -access +rwc
    //-gui
    //+SVSEED=random

// UVM options
    -uvmhome $UVMHOME
    +UVM_VERBOSITY=UVM_HIGH
    +UVM_NO_RELNOTES
    //+UVM_TESTNAME=random_test

// SOME_VIP UVC
    -incdir ../some_vip/sv
    ../some_vip/sv/some_vip_pkg.sv
    ../some_vip/sv/some_vip_if.sv

// RTL
    ../rtl/stub.sv

// Top level
    top.sv
