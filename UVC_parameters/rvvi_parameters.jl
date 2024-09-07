# Vector that specifies the packet's attributes
tr_vec = [
    [true , "logic", "[63:0]", "order"],
    [true , "logic", "[ILEN-1:0]", "insn"],
    [true , "logic", "", "trap"],
    [true , "logic", "", "debug_mode"],
    [true , "logic", "[XLEN-1:0]", "pc_rdata"],
    [true , "logic", "[31:0][XLEN-1:0]", "x_wdata"],
    [true , "logic", "[31:0]", "x_wb"],
    [true , "logic", "[31:0][FLEN-1:0]", "f_wdata"],
    [true , "logic", "[31:0]", "f_wb"],
    [true , "logic", "[31:0][VLEN-1:0]", "v_wdata"],
    [true , "logic", "[31:0]", "v_wb"],
    [true , "logic", "[4095:0][XLEN-1:0]", "csr"],
    [true , "logic", "[4095:0]", "csr_wb"],
    [true , "logic", "", "lrsc_cancel"],
    [true , "logic", "[XLEN-1:0]", "pc_wdata"],
    [true , "logic", "", "intr"],
    [true , "logic", "", "halt"],
    [true , "logic", "[1:0]", "ixl"],
    [true , "logic", "[1:0]", "mode"],
]

# Vector that specifies the interface's signals
signals_if_config = [
    ["logic", "", "valid"],
    ["logic", "[63:0]", "order"],
    ["logic", "[ILEN-1:0]", "insn"],
    ["logic", "", "trap"],
    ["logic", "", "debug_mode"],
    ["logic", "[XLEN-1:0]", "pc_rdata"],
    ["logic", "[31:0][XLEN-1:0]", "x_wdata"],
    ["logic", "[31:0]", "x_wb"],
    ["logic", "[31:0][FLEN-1:0]", "f_wdata"],
    ["logic", "[31:0]", "f_wb"],
    ["logic", "[31:0][VLEN-1:0]", "v_wdata"],
    ["logic", "[31:0]", "v_wb"],
    ["logic", "[4095:0][XLEN-1:0]", "csr"],
    ["logic", "[4095:0]", "csr_wb"],
    ["logic", "", "lrsc_cancel"],
    ["logic", "[XLEN-1:0]", "pc_wdata"],
    ["logic", "", "intr"],
    ["logic", "", "halt"],
    ["logic", "[1:0]", "ixl"],
    ["logic", "[1:0]", "mode"],
]

# Variable that defines if reset is active low or high
rst_is_negedge_sensitive = true

# Define clock and reset names
clock_name = "clk"
reset_name = "rst_n"

# Variable that defines if short names are used
# Ex: monitor becomes mon, driver becomes drv
use_short_names = true
