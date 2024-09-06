# Vector that specifies the packet's attributes
tr_vec = [
    [true , "int", "", "wait_gnt_cycles"],
    [true , "int", "", "wait_rvalid_cycles"],
    [true , "logic", "[31:0]", "addr"],
    [true , "logic", "", "we"],
    [true , "logic", "[ 3:0]", "be"],
    [true , "logic", "[31:0]", "wdata"],
    [true , "logic", "[31:0]", "rdata"],
]

# Vector that specifies the interface's signals
signals_if_config = [
    ["logic", "", "req_o"],
    ["logic", "", "gnt_i"],
    ["logic", "[31:0]", "addr_o"],
    ["logic", "", "we_o"],
    ["logic", "[ 3:0]", "be_o"],
    ["logic", "[31:0]", "wdata_o"],
    ["logic", "", "rvalid_i"],
    ["logic", "[31:0]", "rdata_i"],
]

# Variable that defines if reset is active low or high
rst_is_negedge_sensitive = true

# Define clock and reset names
clock_name = "clk_"
reset_name = "rst_n_"

# Variable that defines if short names are used
# Ex: monitor becomes mon, driver becomes drv
use_short_names = true