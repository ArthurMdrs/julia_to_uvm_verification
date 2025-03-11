# User configurations

# Delete generated files folder before running
user_config.reset_generated_files_folder = true

# UVCs and env generation
user_config.uvc_names = ["some_uvc", "another_uvc"]
# stub_if_names = user_config.uvc_names
user_config.dut_name = "counter"
user_config.gen_clknrst = true
user_config.gen_scoreboard = true
user_config.gen_refmod = true
user_config.use_short_names = true
user_config.agent_has_coverage = false
user_config.env_has_coverage = true
user_config.has_paramaters = true
param1 = sv_params_t("int", "MY_PARAM1", "10")
param2 = sv_params_t("int", "MY_PARAM2", "20")
user_config.params_vec = [ # Make sure to include all your params in this vector!!
    param1, param2
]
user_config.config_inst_convention = "m_config"
user_config.class_names = short_names_dict
user_config.gen_tdefs_pkg = false

# Clock and reset info
user_config.clock_name = "clk"
user_config.reset_name = "rst_n"
user_config.rst_is_negedge_sensitive = true

# Control what files to generate
user_config.run_uvc_gen = true
user_config.run_stub_gen = true
user_config.run_env_gen = true
user_config.run_test_gen = true
user_config.run_top_gen = true
user_config.run_sim_args_gen = true

# Others
user_config.simulator = "xrun"
