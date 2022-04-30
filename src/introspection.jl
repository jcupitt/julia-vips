#=
#
# Introspection object 
#
=#

# a cache of introspection objects
_introspection_cache = Dict{String, Introspection}()

# by name, from a cache
function Introspection(name::String)
    if !haskey(_introspection_cache, name)
        operation = Operation(name)
        _introspection_cache[name] = Introspection(operation, name)
    end

    _introspection_cache[name]
end

# walk an operation, building an Introspection object
function Introspection(operation, operation_name)
    operation_description = get_description(operation)
    operation_flags = get_flags(operation)

    names::Array{Cstring} = []
    flags::Array{Cint} = []
    n_args::Cint = 0

    result = ccall((:vips_object_get_args, _LIBNAME), 
        Cint, 
        (Ptr{GObject}, Ptr{Vector{Cstring}}, Ptr{Vector{Cint}}, Ptr{Cint}),
        get_pointer(operation), Ref(names), Ref(flags), Ref(n_args))
    if result != 0 
        error("unable to get arguments from operation")
    end

    println("n_args = ", n_args)

    arguments = OrderedDict{String, Argument}();
    for i in 0:(n_args - 1)
        if flags[i] & CONSTRUCT
            # libvips uses '-' to separate parts of arg names, but we
            # need '_' for Julia
            name = replace(names[i], '-' => '_')
            gtype = get_gtype(operation, name)
            blurb = get_blurb(operation, name)
            arguments[name] = Argument(name, flags[i], gtype, blurb)
            println("arg = ", name)
        end
    end

    required_input = []
    optional_input = []
    required_output = []
    optional_output = []

    # same, but with deprecated args filtered out ... this is the set we
    # show in documentation
    doc_optional_input = []
    doc_optional_output = []

    # sort args into categories
    for argument in arguments
        if argument.flags & INPUT &&
            argument.flags & REQUIRED &&
            !(argument.flags & DEPRECATED)
            push!(required_input, argument.name)

            # required inputs which we MODIFY are also required outputs
            if argument.flags & MODIFY
                push!(required_output, argument.name)
            end
        end

        if argument.flags & OUTPUT &&
            argument.flags & REQUIRED &&
            !(argument.flags & DEPRECATED)
            push!(required_output, argument.name)
        end

        # deprecated optional args get on to the main arg lists, but are
        # filtered from the documented set
        if argument.flags & _INPUT &&
            !(argument.flags & _REQUIRED)
            push!(optional_input, argument.name)

            # doc args omit deprecated
            if !(argument.flags & DEPRECATED)
                push!(doc_optional_input, argument.name)
            end
        end

        if argument.flags & OUTPUT &&
            !(argument.flags & REQUIRED)
            push!(optional_output, argument.name)

            # doc args omit deprecated
            if !(argument.flags & _DEPRECATED)
                push!(doc_optional_output, argument.name)
            end
        end
    end

    Introspection(operation_name, operation_flags, operation_description, 
        arguments,
        required_input, optional_input, 
        required_output, optional_output,
        doc_optional_input, 
        doc_optional_output)
end
