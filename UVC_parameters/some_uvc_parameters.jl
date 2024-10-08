# Vector that specifies the packet's attributes
tr_vec = [
  [true, "bit", "[7:0]", "data_to_send"],
  [false, "bit", "[7:0]", "data_received"]]

# Vector that specifies the interface's signals
signals_if_config = [
  ["logic", "1", "ready_o"],
  ["logic", "1", "valid_i"],
  ["logic", "[7:0]", "data_i"],
  ["logic", "[7:0]", "data_o"] ]

# Variable that defines if reset is active low or high
rst_is_negedge_sensitive = true

# Define clock and reset names
clock_name = "clock"
reset_name = "nreset"

# Variable that defines if short names are used
# Ex: monitor becomes mon, driver becomes drv
use_short_names = false

# UNCOMMENT ONLY IF NECESSARY!!!
# This will overwrite the vectors defined in global_vectors.jl
# Check the documentation's "How to use" section for more info
#
# Variables that define which classes will be included in the package
# pkg_classes.packet = false
# pkg_classes.sequence_lib = false
# pkg_classes.monitor = false
# pkg_classes.sequencer = false
# pkg_classes.driver = false
# pkg_classes.coverage = false
# pkg_classes.agent = false
#
# Variables that define which classes will be generated as files
# gen_classes.packet = false
# gen_classes.sequence_lib = false
# gen_classes.monitor = false
# gen_classes.sequencer = false
# gen_classes.driver = false
# gen_classes.coverage = false
# gen_classes.agent = false
# gen_classes.pkg = false
# gen_classes.interface = false
#
# UNCOMMENT ONLY IF NECESSARY!!!