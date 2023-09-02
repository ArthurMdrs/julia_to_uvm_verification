This example includes the generation of one VIP named "some_vip". 
The test and run.f gen functions were not enabled, so these files 
are not generated. 
The global vectors were overriden. Note that pkg_vec does not 
contain "monitor", so the monitor is not included in the package. 
Also, vec_classes does not contain "driver", so this class is not
generated.
Notice that rst_is_negedge_sensitive is false, so the dut is 
assumed to have an active high reset.