# This variable determines if the generated files folder
# will be cleared before a new generation
reset_generated_files_folder = true

# Vector that defines the VIPs (or UVCs) names
vip_names = ["fft_16_4_in", "fft_16_4_out"]

# Vector that defines which VIPs will be included in the
# stub DUT, top level, test library and run.f file
stub_if_names = vip_names

# Flags that define which files will be generated
run_vip_gen = true
run_stub_gen = true
run_test_gen = true
run_top_gen = true
run_run_file_gen = true
