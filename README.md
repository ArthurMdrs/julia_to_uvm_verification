# Julia to UVM Verification

This is a Julia script that generates UVM interface UVCs, environment, tests and top file in SystemVerilog.

## Requirements

As the entire code is written in the Julia programming language, it is required to have Julia installed. For Julia installation, please refer to [their website](https://julialang.org).

We use the following packages, which you will need to install:
- [YAML](https://github.com/JuliaData/YAML.jl);
- [StructTypes](https://github.com/JuliaData/StructTypes.jl);
- [ArgParse](https://carlobaldassi.github.io/ArgParse.jl/latest/).
<!-- We also use the YAML package, which you might have to install. Please refer to [their GitHub page](https://github.com/JuliaData/YAML.jl) for more information. -->

To install a package:
- Type `julia` in your terminal to open the julia interactive terminal.
- Press the `]` key to go into package manager mode.
- Use `add <package_name>` to install the package.

You might want to use a virtual environment to encapsulate your packages. 

## How to use

WIP