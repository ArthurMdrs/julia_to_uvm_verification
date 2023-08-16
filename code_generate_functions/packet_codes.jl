# ***********************************
# Packet Codes!!!!!
# ***********************************
# Forma do vetor para gerar o packet:
#  is_rand? | type | length | name
# 
# Ex:
# packet_vec = [
#   [true , "bit", "[7:0]", "addr" ],
#   [false, "bit", "[7:0]", "data" ],
#   [false, "bit", "1"    , "value"],
#   [true , "bit", "1"    , "bit_" ]]
#
# Esse vetor vem do arquivo VIP_parameters/(VIP name)_parameters.jl
# ***********************************
gen_line_convert_to_string(vec, tabs) = 
    "$(tabs)string_aux = {string_aux, \$sformatf(\"** $(vec[4]) value: %2h\\n\", $(vec[4]))};\n"
gen_line_object_utils(vec, tabs) = 
    "$(tabs)`uvm_field_int($(vec[4]), UVM_ALL_ON)\n"
gen_line_instanciate_obj(vec, tabs) = 
    "$(tabs)$((vec[1]) ? "rand" : "    ") $(vec[2]) $((vec[3]=="1") ? "     " : vec[3]) $(vec[4]);\n"

gen_packet_base(prefix_name, vec) = """
    class $(prefix_name)_packet extends uvm_sequence_item;

    $(gen_long_str(vec, "    ", gen_line_instanciate_obj))
        `uvm_object_utils_begin($(prefix_name)_packet)
    $(gen_long_str(vec, "        ", gen_line_object_utils))    `uvm_object_utils_end

        function new(string name="$(prefix_name)_packet");
            super.new(name);
        endfunction: new

        // Type your constraints!

        function string convert2string();
            string string_aux;

            string_aux = {string_aux, "\\n***************************\\n"};
    $(gen_long_str(vec, "        ", gen_line_convert_to_string))
            string_aux = {string_aux, "***************************"};
            return string_aux;
        endfunction: convert2string

        // function void post_randomize();
        // endfunction: post_randomize

    endclass: $(prefix_name)_packet
    """
# ****************************************************************