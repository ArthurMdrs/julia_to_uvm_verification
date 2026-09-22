
function print_fields(obj; indent=0)
    prefix = " "^indent

    for field in fieldnames(typeof(obj))

        # Field was never initialized
        if !isdefined(obj, field)
            println("$(prefix)$(field): <undefined>")
            continue
        end

        value = getfield(obj, field)

        # Explicitly initialized to nothing
        if value === nothing
            println("$(prefix)$(field): nothing")

        # Vectors containing only numbers
        elseif value isa AbstractVector{<:Number}
            println("$(prefix)$(field): [$(join(value, ", "))]")

        # Dictionaries
        elseif value isa AbstractDict
            println("$(prefix)$(field):")

            for (key, val) in value

                if val === nothing
                    println("$(prefix)  $(key): nothing")

                elseif val isa AbstractString ||
                    val isa Number ||
                    val isa Bool ||
                    val isa Symbol ||
                    val isa Enum
                    println("$(prefix)  $(key): $(val)")

                elseif val isa AbstractVector{<:Number}
                    println("$(prefix)  $(key): [$(join(val, ", "))]")

                elseif isstructtype(typeof(val))
                    println("$(prefix)  $(key):")
                    print_fields(val; indent=indent + 4)

                else
                    println("$(prefix)  $(key):")
                    println("$(prefix)    $(val)")
                end
            end

        # General vectors
        elseif value isa AbstractVector
            println("$(prefix)$(field):")

            for (i, item) in enumerate(value)

                if item isa AbstractVector{<:Number}
                    println("$(prefix)  [$(i)]: [$(join(item, ", "))]")

                elseif isstructtype(typeof(item))
                    item_fields = fieldnames(typeof(item))

                    # Print first field on the same line as [i]:
                    if !isempty(item_fields)
                        first_field = item_fields[1]

                        if isdefined(item, first_field)
                            first_value = getfield(item, first_field)

                            if first_value isa AbstractVector{<:Number}
                                first_value_str = "[$(join(first_value, ", "))]"
                            else
                                first_value_str = string(first_value)
                            end

                            println("$(prefix)  [$(i)]:  $(first_field): $(first_value_str)")
                        else
                            println("$(prefix)  [$(i)]:  $(first_field): <undefined>")
                        end

                        # Print remaining fields normally
                        for field in item_fields[2:end]
                            if !isdefined(item, field)
                                println("$(prefix)        $(field): <undefined>")
                                continue
                            end

                            field_value = getfield(item, field)

                            if field_value === nothing
                                println("$(prefix)        $(field): nothing")
                            elseif field_value isa AbstractVector{<:Number}
                                println("$(prefix)        $(field): [$(join(field_value, ", "))]")
                            else
                                println("$(prefix)        $(field): $(field_value)")
                            end
                        end
                    else
                        println("$(prefix)  [$(i)]:")
                    end

                elseif item === nothing
                    println("$(prefix)  [$(i)]: nothing")

                elseif item isa AbstractString ||
                    item isa Number ||
                    item isa Bool ||
                    item isa Symbol ||
                    item isa Enum
                    println("$(prefix)  [$(i)]: $(item)")

                else
                    println("$(prefix)  [$(i)]: $(item)")
                end
            end

        # Strings and other scalar values
        elseif value isa AbstractString ||
               value isa Number ||
               value isa Bool ||
               value isa Symbol ||
               value isa Enum
            println("$(prefix)$(field): $(value)")

        # Nested structs
        elseif isstructtype(typeof(value))
            println("$(prefix)$(field):")
            print_fields(value; indent=indent + 2)

        # Anything else
        else
            println("$(prefix)$(field): $(value)")
        end
    end
end