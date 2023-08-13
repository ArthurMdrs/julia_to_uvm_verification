class another_vip_packet extends uvm_sequence_item;

    rand bit    [7:0] data_to_send;
    rand logic [15:0] random_data;

    `uvm_object_utils_begin(another_vip_packet)
        `uvm_field_int(data_to_send, UVM_ALL_ON)
        `uvm_field_int(random_data, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="another_vip_packet");
        super.new(name);
    endfunction: new

    // Type your constraints!

    function string convert2string();
        string string_aux;

        string_aux = {string_aux, "\n***************************\n"};
        string_aux = {string_aux, $sformatf("** data_to_send value: %2h\n", data_to_send)};
        string_aux = {string_aux, $sformatf("** random_data value: %2h\n", random_data)};

        string_aux = {string_aux, "***************************"};
        return string_aux;
    endfunction: convert2string

    // function void post_randomize();
    // endfunction: post_randomize

endclass: another_vip_packet
