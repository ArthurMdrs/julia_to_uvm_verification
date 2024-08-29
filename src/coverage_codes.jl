# ***********************************
# Coverage Codes!!!!!
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
# This vector comes from the file VIP_parameters/(VIP name)_parameters.jl
# ***********************************

gen_line_coverpoint(vec, tabs) = """
$(tabs)cp_$(vec[4]): coverpoint cov_transaction.$(vec[4]);\n"""

gen_coverage_base(prefix_name, vec) = begin
    name = use_short_names ? short_names_dict["coverage"] : "cov"
    tr_name = use_short_names ? short_names_dict["transaction"] : "transaction"
    return """
    class $(prefix_name)_$(name) extends uvm_subscriber #($(prefix_name)_$(tr_name));

        real coverage_value;
        $(prefix_name)_$(tr_name) cov_transaction;

        `uvm_component_utils_begin($(prefix_name)_$(name))
            `uvm_field_real(coverage_value, UVM_ALL_ON)
        `uvm_component_utils_end

        covergroup $(prefix_name)_covergroup;
            option.per_instance = 1;
            option.name = {get_full_name(), ".", "covergroup"};
            // option.at_least = 3;
            // option.auto_bin_max = 256;
            // option.cross_auto_bin_max = 256;
    $(gen_long_str(vec, "        ", gen_line_coverpoint))    endgroup : $(prefix_name)_covergroup

        function new (string name, uvm_component parent);
            super.new(name, parent);
            $(prefix_name)_covergroup = new();
        endfunction: new

        function void report_phase (uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) COVERAGE", \$sformatf("Coverage: %2.2f%%", get_coverage()), UVM_NONE)
        endfunction : report_phase

        function void sample ($(prefix_name)_$(tr_name) t);
            cov_transaction = t;
            $(prefix_name)_covergroup.sample();
        endfunction : sample

        function real get_coverage ();
            return $(prefix_name)_covergroup.get_inst_coverage();
        endfunction : get_coverage

        function void write($(prefix_name)_$(tr_name) t);      
            sample(t); // sample coverage with this transaction
            coverage_value = get_coverage();
        endfunction : write

    endclass : $(prefix_name)_$(name)
    """
    end
# ****************************************************************