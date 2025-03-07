
######################## IMPORTS, FUNCTIONS AND INCLUDES ########################

# Importing Dash package
using Dash

# Global parameters
include("./global_vectors.jl")

# Functions
gen_long_str(vec, tabs, line_gen_func) = begin
    str_aux = ""
    for x in vec
        str_aux *= line_gen_func(x, tabs)
    end
    return str_aux
end
output_file_setup(dir; reset_folder=true) = begin
    if isdir(dir)
        if (reset_folder)
            rm(dir, recursive=true, force = true)
            mkdir(dir)
        end
    else
        mkdir(dir)
    end
end
write_file(file_dir, txt_string) = begin
    open(file_dir, "w") do io
        write(io, txt_string)
    end;
end

######################## OPTIONS ########################

app_style = Dict(
    "backgroundColor" => "#222222",
    "color" => "#7FDBFF"
)

######################## HTML DIVS ########################

if_names_div = [dcc_input(id = "UVC_name_box_1", value = "some_uvc", type = "text")]

# code_gen_params_input = html_div(
#     id = "code_gen_params_input",
#     children = html_table(
#         id = "code_gen_params_table",
#         # style = Dict(
#         #     "width" => "600px",
#         #     "border" => "2px solid", 
#         #     "borderSpacing" => "20px"
#         # ),
#         children = html_tr(
#             id = "code_gen_params_table_row1",
#             children = [
#                 html_td(
#                     id = "code_gen_params_table_cell1",
#                     style = Dict("width" => "50%"),
#                     children = [
#                         html_label("Reset generated files folder?"),
#                         dcc_radioitems(
#                             id = "reset_folder",
#                             options = [
#                                 Dict("label" => "Yes", "value" => true), 
#                                 Dict("label" => "No", "value" => false)
#                             ],
#                             value = true,
#                             inline = true
#                         ), 
#                         html_br(),
#                         html_label("What should be generated?"),
#                         dcc_checklist(
#                             id = "gen_checklist",
#                             options = [
#                                 Dict("label" => "UVCs", "value" => "UVCs"), 
#                                 Dict("label" => "Stub DUT", "value" => "Stub"), 
#                                 Dict("label" => "Test", "value" => "Test"), 
#                                 Dict("label" => "Top level module", "value" => "Top"), 
#                                 Dict("label" => "run.f file with xrun arguments", "value" => "run.f"),
#                             ],
#                             value = ["UVCs", "Stub", "Test", "Top", "run.f"]
#                         )
#                     ]
#                 ),
#                 html_td(
#                     id = "code_gen_params_table_cell2",
#                     style = Dict("width" => "50%"),
#                     children = [
#                         html_label("UVC names"),
#                         html_br(),
#                         # html_div([dcc_input(id = "UVC_name_box_1", value = "some_uvc", type = "text")], id = "if_names_div"),
#                         html_div(if_names_div, id = "if_names_div"),
#                         html_br(),
#                         html_button("Add", id = "add_UVC", n_clicks = 0),
#                         html_button("Remove", id = "remove_UVC", n_clicks = 0),
#                         html_br(), html_br(),
#                         html_button("Next", id = "gen_params_done_button", n_clicks = 0),
#                     ]
#                 )
#             ]
#         )
#     )
# )

code_gen_params_input = [
    html_td(
        id = "code_gen_params_table_cell1",
        style = Dict("width" => "50%"),
        children = [
            html_label("Reset generated files folder?"),
            dcc_radioitems(
                id = "reset_folder",
                options = [
                    Dict("label" => "Yes", "value" => true), 
                    Dict("label" => "No", "value" => false)
                ],
                value = true,
                inline = true
            ), 
            html_br(),
            html_label("What should be generated?"),
            dcc_checklist(
                id = "gen_checklist",
                options = [
                    Dict("label" => "UVCs", "value" => "UVCs"), 
                    Dict("label" => "Stub DUT", "value" => "Stub"), 
                    Dict("label" => "Test", "value" => "Test"), 
                    Dict("label" => "Top level module", "value" => "Top"), 
                    Dict("label" => "run.f file with xrun arguments", "value" => "run.f"),
                ],
                value = ["UVCs", "Stub", "Test", "Top", "run.f"]
            )
        ]
    ),
    html_td(
        id = "code_gen_params_table_cell2",
        style = Dict("width" => "50%"),
        children = [
            html_label("UVC names"),
            html_br(),
            html_div(if_names_div, id = "if_names_div"),
            html_br(),
            html_button("Add", id = "add_UVC", n_clicks = 0),
            html_button("Remove", id = "remove_UVC", n_clicks = 0),
            html_br(), html_br(),
            html_button("Next", id = "gen_params_done_button", n_clicks = 0),
        ]
    )
]

code_gen_params_output = html_div(
    id = "code_gen_params_output",
    children = [
        html_h2("code_generate_parameters.jl"),
        html_br(),
        html_label("reset_generated_files_folder = "),
        html_label(id = "reset_folder_val"),
        html_br(),
        html_label("vip_names = "),
        html_label(id = "vip_names_val"),
        html_br(),
        html_label("stub_names = "),
        html_label(id = "stub_names_val"),
        html_br(),
        html_label("run_vip_gen = "),
        html_label(id = "vip_gen_val"),
        html_br(),
        html_label("run_stub_gen = "),
        html_label(id = "stub_gen_val"),
        html_br(),
        html_label("run_test_gen = "),
        html_label(id = "test_gen_val"),
        html_br(),
        html_label("run_top_gen = "),
        html_label(id = "top_gen_val"),
        html_br(),
        html_label("run_run_file_gen = "),
        html_label(id = "run_file_val"),
    ]
)

######################## THE APP ########################

app = dash()

app.layout = html_div(style = app_style) do
    html_h1(
        "Julia to UVM verification",
        style = Dict("color" => "#7FDBFF", "textAlign" => "center"),
    ),
    html_table(
        style = Dict(
            "width" => "100%",
            "border" => "2px solid", 
            "borderSpacing" => "20px"
        ),
        children = [
            html_tr(
                id = "app_row1",
                children = [
                    html_td(
                        id = "app_cell1",
                        style = Dict("width" => "50%"),
                        children = code_gen_params_input
                    ), 
                    html_td(
                        id = "app_cell2",
                        style = Dict("width" => "50%"),
                        children = code_gen_params_output
                    )
                ]
            )
        ]
    ),
    html_div(id = "empty")
end

######################## CALLBACKS ########################

callback!( app, 
    Output("if_names_div", "children"), 
    Input("add_UVC", "n_clicks"), 
    Input("remove_UVC", "n_clicks"),
    State("if_names_div", "children")
) do add_clicks, remove_clicks, previous_state
    if (add_clicks == 0) && (remove_clicks == 0)
        throw(PreventUpdate())
    end
    ctx = callback_context()
    if length(ctx.triggered) == 0
        button_id = ""
    else
        button_id = split(ctx.triggered[1].prop_id, ".")[1]
    end

    # PROBLEM: HOW TO MAKE SO THE NAMES WON'T GO AWAY??
    if (button_id == "add_UVC")
        push!(if_names_div, dcc_input(id = "UVC_name_box_$(length(if_names_div)+1)", value = "some_uvc", type = "text"))
    elseif (button_id == "remove_UVC" && length(if_names_div) > 1)
        pop!(if_names_div)
    end
    return if_names_div

    # CODE BELOW DOES NOT WORK
    # next_state = []
    # push!(next_state, previous_state)
    # next_state = previous_state
    # if (button_id == "add_UVC")
    #     push!(next_state, dcc_input(id = "UVC_name_box_$(length(next_state)+1)", value = "some_uvc", type = "text"))
    # elseif (button_id == "remove_UVC" && length(next_state) > 1)
    #     pop!(next_state)
    # end
    # return next_state
end

callback!( app, 
    Output("reset_folder_val", "children"), 
    Output("vip_names_val", "children"), 
    Output("stub_names_val", "children"), 
    Output("vip_gen_val", "children"), 
    Output("stub_gen_val", "children"), 
    Output("test_gen_val", "children"), 
    Output("top_gen_val", "children"), 
    Output("run_file_val", "children"), 
    Input("gen_params_done_button", "n_clicks"),
    State("reset_folder", "value"),
    State("gen_checklist", "value"),
    # State("if_names_div", "children")
) do n_clicks, reset_folder_val, gen_checklist_val
    if (n_clicks == 0)
        throw(PreventUpdate())
    end
    vip_names = []
    stub_if_names = []
    run_vip_gen = false
    run_stub_gen = false
    run_test_gen = false
    run_top_gen = false
    run_run_file_gen = false
    vip_gen_val = "false"
    stub_gen_val = "false"
    test_gen_val = "false"
    top_gen_val = "false"
    run_file_val = "false"
    reset_generated_files_folder = reset_folder_val
    reset_folder_str = (reset_folder_val) ? "true" : "false"
    for i in gen_checklist_val
        if (i == "UVCs") 
            run_vip_gen = true
            vip_gen_val = "true"
        end
        if (i == "Stub") 
            run_stub_gen = true 
            stub_gen_val = "true"
        end
        if (i == "Test") 
            run_test_gen = true
            test_gen_val = "true"
        end
        if (i == "Top") 
            run_top_gen = true 
            top_gen_val = "true"
        end
        if (i == "run.f") 
            run_run_file_gen = true 
            run_file_val = "true"
        end
    end
    vip_names_str = "["
    for i in if_names_div
        push!(vip_names, i.value)
        if (i != last(if_names_div))
            vip_names_str = vip_names_str*i.value*", "
        else
            vip_names_str = vip_names_str*i.value*"]"
        end
    end
    stub_if_names = vip_names
    stub_names_str = vip_names_str    

    str = """
        reset_generated_files_folder = $(reset_generated_files_folder)
        vip_names = $(vip_names)
        stub_if_names = $(stub_if_names)
        run_vip_gen = $(run_vip_gen)
        run_stub_gen = $(run_stub_gen)
        run_test_gen = $(run_test_gen)
        run_top_gen = $(run_top_gen)
        run_run_file_gen = $(run_run_file_gen)"""
    write_file("code_generate_parameters.jl", str)

    return (reset_folder_str, vip_names_str, stub_names_str, 
            vip_gen_val, stub_gen_val, test_gen_val, top_gen_val, run_file_val)
end


######################## RUN THE APP ########################

run_server(app, "0.0.0.0", debug=true)

# go to http://127.0.0.1:8050/