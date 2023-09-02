This example includes the generation of two VIPs named "some_vip"
and "another_vip". All gen functions were enabled. 
The global vectors were not overriden. 
Notice that only some_vip was included in the test and stub. That's  
because another_vip is not in the stub_if_names vector.
Also, the port named "data" in the stub has type NOTYPE because its 
name does not end with "_i" or "_o".