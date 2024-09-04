# ***********************************
# Transaction Codes!!!!!
# ***********************************
# Form of the vector to generate the transaction:
#  is_rand? | type | length | name
# 
# E.g.:
# tr_vec = [
#   [true , "bit", "[7:0]", "addr" ],
#   [false, "bit", "[7:0]", "data" ],
#   [false, "bit", "1"    , "value"],
#   [true , "bit", "1"    , "bit_" ]]
#
# This vector comes from the file UVC_parameters/(UVC name)_parameters.jl
# ***********************************
gen_line_convert_to_string(vec, tabs) = 
    "$(tabs)string_aux = {string_aux, \$sformatf(\"** $(vec[4]) value: %2h\\n\", $(vec[4]))};\n"
gen_line_object_utils(vec, tabs) = 
    "$(tabs)`uvm_field_int($(vec[4]), UVM_ALL_ON)\n"
gen_line_instanciate_obj(vec, tabs) = 
    "$(tabs)$((vec[1]) ? "rand" : "    ") $(vec[2]) $((vec[3]=="1" || vec[3]=="") ? "      " : vec[3]) $(vec[4]);\n"

gen_tr_base(prefix_name, vec) = begin 
    name = use_short_names ? short_names_dict["transaction"] : "transaction"
    return """
    class $(prefix_name)_$(name) extends uvm_sequence_item;

    $(gen_long_str(vec, "    ", gen_line_instanciate_obj))
        `uvm_object_utils_begin($(prefix_name)_$(name))
    $(gen_long_str(vec, "        ", gen_line_object_utils))    `uvm_object_utils_end

        function new(string name="$(prefix_name)_$(name)");
            super.new(name);
        endfunction: new

        // Type your constraints!
        constraint some_constraint {}

        function string convert2string();
            string string_aux;

            string_aux = {string_aux, "\\n***********************************\\n"};
    $(gen_long_str(vec, "        ", gen_line_convert_to_string))        string_aux = {string_aux, "***********************************"};
            return string_aux;
        endfunction: convert2string

        // function void post_randomize();
        // endfunction: post_randomize

    endclass: $(prefix_name)_$(name)
    """
end

gen_clknrst_tr() = begin 
    prefix_name = "clknrst"
    name = use_short_names ? short_names_dict["transaction"] : "transaction"
    return """
    class $(prefix_name)_$(name) extends uvm_sequence_item;
        
        rand $(prefix_name)_action_enum   action;
        rand int unsigned          rst_assert_duration;     // In ps
        rand int unsigned          clk_period;              // In ps
        rand $(prefix_name)_init_val_enum initial_clk_val;
        
        `uvm_object_utils_begin($(prefix_name)_$(name))
            `uvm_field_enum($(prefix_name)_action_enum  , action         , UVM_ALL_ON)
            `uvm_field_int (rst_assert_duration                   , UVM_ALL_ON)
            `uvm_field_int (clk_period                            , UVM_ALL_ON)
            `uvm_field_enum($(prefix_name)_init_val_enum, initial_clk_val, UVM_ALL_ON)
        `uvm_object_utils_end

        function new(string name="$(prefix_name)_$(name)");
            super.new(name);
        endfunction: new

        constraint max_clk_period {
            clk_period <= 20_000; // 20ns
        }

        constraint max_rst_assert_duration {
            rst_assert_duration <= 15_000; // 15ns
        }

    endclass: $(prefix_name)_$(name)
    """
end

# ****************************************************************