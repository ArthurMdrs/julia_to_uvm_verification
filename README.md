# Julia to UVM Verification

 This is a Julia script that generates UVM interface UVCs, test file and top file in SystemVerilog.

 The main goal of this generator is to create the UVC files, but it is convenient to generate a test to garantee that everything works properly before incorporating to the verification environment. It is also nice to have the pre-typed instantiations and connections from the top level module, which are quite prone for typos. 

## Requirements

As the entire code is written in the Julia programming language, it is required to have Julia installed. For Julia installation, please refer to [their website](https://julialang.org).

## How to use

To generate the files, you will need to run the [run_script.jl](run_script.jl), located in the root directory of the repository. Running the script will create a folder called `generated_files`, where your files will be. Before you do that, there are some preparations for you to do.

In the root of the repository, there is a file named [code_generate_parameters.jl](code_generate_parameters.jl). You will need to edit the variables in this file to customize the file generation. Let's talk about those variables.

>reset_generated_files_folder = true

A `true` value in `reset_generated_files_folder` means the `generated_files` folder will be deleted before proceeding with the new generation. `false` will leave it intact, which might be useful if you made a mistake and only want to generate some specific files in the next iteration.

>uvc_names = ["some_uvc", "another_uvc"]

This vector represents the names of the UVCs you want to generate. You can add as many as you want.

>stub_if_names = ["some_uvc", "another_uvc"]

This vector represents the names of the UVCs that will be included in the tests file, stub DUT, top level and run.f file. You can copy from `uvc_names`, but you don't have to. Just keep in mind that names that UVCs that weren't generated and therefore don't have a corresponding folder in the `generated_files/` will be ignored.

>run_uvc_gen = true  
>run_stub_gen = true  
>run_test_gen = true  
>run_top_gen = true  
>run_run_file_gen = true

These are flags that will tell the script what to generate. You can generate: 

- The UVCs, that will each have a folder with its own name in `generated_files/`. This usually stays `true`, unless you have already generated the UVCs in previous iterations. Remember to set `reset_generated_files_folder` to `false` if that's the case.
- The stub DUT, which is only here because the top level module will instantiate it and connect the interface signals to it. This will be created in `generated_files/rtl/`.
- An example tests library file, which only contains a base test and a random test. It is used to test the generated files. This will be created in `generated_files/test_top/`.
- The top level module, which instantiates the interfaces and the DUT. It also has an initial block that performs a reset. To generate the top file, you need to also generate the stub DUT. The top level will be created in `generated_files/test_top/`.
- A `run.f` file to make testing the generated UVCs easier. It has all the arguments necessary for the command line to execute the test. For now, this is only compatible with Cadence Design System's Xcelium. This will be created in `generated_files/test_top/`. Open a terminal in this folder and do `xrun -f run.f` in the command line to run the test.

The other thing you will have to edit is the `UVC_parameters` folder. Inside this folder, you have to make one file for each UVC that you want to generate, which will contain the parameters for that UVC generation. The name of the file must be `(UVC name)_parameters.jl`. For example, a UVC named "random" would require the file `UVC_parameters/random_parameters.jl`. There are already some examples in there for you to copy and paste. Let's take a look at what these files must contain. 

>packet_vec = [  
>  [true, "bit  ", " [7:0]", "data_to_send"],  
>  [true, "logic", "[15:0]", "random_data"] ]

This vector is used by the packet class, it corresponds to its attributes. The first field of each element is a boolean value that defines if the field should be declared as `rand` for randomization of packets. Then we got the type, the size and endianness and the field name. 

>signals_if_config = [  
>  ["logic", "1", "other_valid_i"],  
>  ["logic", "[7:0]", "other_data_o"] ]

This vector represents the interface signals that are connected to the DUT. Its format is just like the previous one, but this has no randomization information. Note that the signal "other_valid_i" has "1" instead of a size. That will cause it to be a single bit signal. You can also just leave it as an empty string "". For the program to understand if the signal is an input or an output, its name must end with either "_i" or "_o", respectively, otherwise you will see "NOTYPE" in the DUT ports. 

>rst_is_negedge_sensitive = true

When this is `true`, the DUT resets on the negative edge of the reset signal. 

>if_vec = ["clk", ["rst_n", rst_is_negedge_sensitive], signals_if_config]

This takes the last two variables that we saw and add them together with the clock name and reset name in a single vector. 

>pkg_classes.(name) = false

These will define which files will be included in the UVC package. Note that this is commented out in the example files. That is because it is already defined in [global_vectors.jl](global_vectors.jl), and uncommenting it in the parameters file will only overwrite the global vector for this UVC.

>gen_classes.(name) = false

These will define which files/classes will be generated for the UVC. Like the `pkg_classes`, this is here to overwrite the vector defined in [global_vectors.jl](global_vectors.jl).

Now you know about all the preparations. To run the script, open the command prompt in the root directory and run the command `julia run_script.jl`. The `generated_files` folder will be created and all the files will be in it.

## How to test the generated files

This program can generate a `run.f` file with all the necessary command line arguments to run the generated random test with Cadence's Xcelium. To run the test, open the command prompt in the `generated_files/test_top/` folder and run the command `xrun -f run.f`. If you don't have access to Xcelium, you will have to make your own run file. Support for other tools could be added in the future. Keep in mind that, in order for the test to work properly, all files and classes must be generated.

At the beginning of the simulation, the components hierarchy is printed. Check if it corresponds to what you expected. The random sequence located in the sequence_lib.sv file generates and sends 3 random packets. If you simulate with UVM_HIGH verbosity level, you should see, for each packet, 2 messages with the packet info when driving a packet (one from the driver and one from the interface) and 2 messages with the packet info when collecting a packet (one from the interface and one from the monitor). If you don't want to see reports from the interface, run the simulation with verbosity level of UVM_MEDIUM or delete the uvm_info lines from the interfaces. At the end of the simulation, you should see a report from each UVC's driver and monitor saying that 3 packets were sent and 3 packets were collected.

## Examples

THESE EXAMPLES ARE OUTDATED AND WILL BE REPLACED IN THE FUTURE. 

You will find an examples folder in the root of the repository. Each contains the generated files and the parameter used for the generation. The examples are the following:

- Example 1:

>This example includes the generation of two UVCs named "some_uvc" and "another_uvc".  
>All gen functions were enabled.  
>The global vectors were not overriden. 

- Example 2:

>This example includes the generation of two UVCs named "some_uvc" and "another_uvc".  
>All gen functions were enabled.  
>The global vectors were not overriden.  
>Notice that only some_uvc was included in the test and stub. That's because another_uvc is not in the stub_if_names vector.  
>Also, the port named "data" in the stub has type NOTYPE because its name in some_uvc_parameters.jl does not end with "_i" or "_o".

- Example 3:

>This example includes the generation of one UVC named "some_uvc".  
>The test and run.f gen functions were not enabled, so these files are not generated.  
>The global vectors were overriden. Note that pkg_classes.monitor is set to false, so the monitor is not included in the package. Also, gen_classes.driver is set to false, so this class is not generated. These overwrites can be observed in some_uvc_parameters.jl.
>Notice that rst_is_negedge_sensitive is false, so the dut is assumed to have an active high reset.

## Final words

If you have any questions or suggestions or if you found a bug, please contact us at pedromedeiros.egnr@gmail.com.