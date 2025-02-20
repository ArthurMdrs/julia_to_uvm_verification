uvc_names = ["some_uvc", "obi"]
stub_if_names = uvc_names
dut_name = "counter"

gen_clknrst = true
gen_scoreboard = true
gen_refmod = true

has_paramaters = true
params_vec = [
    ["int", "an_int_param", "10"],
    ["bit [3:0]", "a_bit_param", "4'hF"] ]

use_short_names = false

agent_has_coverage = false
env_has_coverage = true

run_uvc_gen = true
run_stub_gen = true
run_env_gen = true
run_test_gen = true
run_top_gen = true
run_sim_args_gen = true

# Simulators supported: ["xrun", "dsim"]
simulator = "xrun"