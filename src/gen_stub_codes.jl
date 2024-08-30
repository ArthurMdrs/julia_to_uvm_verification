# ***********************************
# Stub Codes!!!!!
# ***********************************
# Form of the vector to generate the stub:
#  uvc1_name | uvc2_name | ...
# 
# E.g.:
# stub_if_names = ["uvc_test"]
# 
# This vector comes from the file code_generate_parameters.jl
#
# It is also used the file /generated_files/(UVC name)/parameter_folder/(UVC name)_parameters.jl
# Which is generated in the UVC generation
# ***********************************

# OBS.: The function gen_line_if_signal() comes from interface_codes.jl
gen_line_stub_if_signals(vec, tabs) = gen_line_if_signal(vec, tabs; end_of_line=",")
gen_stub_if_signals(if_vector, gen_line, tabs) = begin
    str = ""
    for x in if_vector
        str *= "\n$(tabs)// Signals from $(x[1])'s interface - begin\n"
        str *= gen_long_str(x[2], tabs*"    ", gen_line)
        str = (x == if_vector[end]) ? str[1:end-2]*"\n" : str
        str *= "$(tabs)// Signals from $(x[1])'s interface - end\n"
    end
    return str
end
gen_stub_parameters_str_file(if_vector, stub_if_names, clk_name, rst_name) = 
    "if_vector = $(if_vector)\nstub_if_names = $(stub_if_names)\nclk_rst_names = $([clk_name, rst_name])"
update_signals_if_config(signals_if_config) = begin
    out_vec = []
    for x in signals_if_config
        if x[3][end-1:end] == "_o"
            push!(out_vec, ["output reg", x[2], x[3]])
        elseif x[3][end-1:end] == "_i"
            push!(out_vec, ["input     ", x[2], x[3]])
        else
            push!(out_vec, ["NOTYPE    ", x[2], x[3]])
        end
    end
    return out_vec
end
get_interface_signals() = begin
    if_gather = []
    item_to_delete = []
    for x in stub_if_names
        try
            include(pwd()*"/generated_files/"*x*"/parameter_folder/"*x*"_parameters.jl")
            push!(if_gather,[x,update_signals_if_config(signals_if_config)])
        catch
            println("It was not possible to open the UVC '$(x)' for stub/test generation.")
            push!(item_to_delete, x) 
        end
    end
    setdiff!(stub_if_names, item_to_delete)
    return if_gather
end

stub_gen() = (!run_stub_gen) ? "" : begin
    if_vector = get_interface_signals()
    clk_name = if_vec[1]
    rst_name = if_vec[2]

    output_file_setup("generated_files/rtl")
    write_file("generated_files/rtl/stub.sv", gen_stub_base([clk_name, rst_name], if_vector))
    write_file("generated_files/rtl/stub_parameters.jl", 
                gen_stub_parameters_str_file(if_vector, stub_if_names, clk_name, rst_name))
end

gen_stub_base(clk_rst_names, vec) = begin 
    return """
    module stub (input $(clk_rst_names[1]), input $(clk_rst_names[2][1]), $(gen_stub_if_signals(vec, gen_line_stub_if_signals, "    "))    );

        always @(posedge $(clk_rst_names[1]) or $( (clk_rst_names[2][2]) ? "negedge" : "posedge" ) $(clk_rst_names[2][1])) begin
            if($( (clk_rst_names[2][2]) ? "~" : "" )$(clk_rst_names[2][1])) begin
                // Reset logic
            end
            else begin
                // Sequencial logic
            end
        end

        always @(*) begin
            // Combinational logic
        end

    endmodule: stub
    """
    end
# ****************************************************************
