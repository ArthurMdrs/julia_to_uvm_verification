This example includes the generation of one VIP named "some_vip". 
The test and run.f gen functions were not enabled, so these files 
are not generated. 
The global vectors were overriden. Note that pkg_classes.monitor 
is set to false, so the monitor is not included in the package. 
Also, gen_classes.driver is set to false, so this class is not
generated. These overwrites can be observed in some_vip_parameters.jl.
Notice that rst_is_negedge_sensitive is false, so the dut is 
assumed to have an active high reset.