#=
#
# Introspection object 
#
=#

# a cache of introspection objects
_introspection_cache = Dict{String, Introspection}()

# by name, from a cache
function Introspection(name::String)::Introspection
    if !haskey(_introspection_cache, name)
        operation = Operation(name)
        _introspection_cache[name] = Introspection(operation)
    end

    _introspection_cache[name]
end

# walk an operation, building an Introspection object
function Introspection(operation::Operation)::Introspection
    description = get_description(operation)
    flags = get_flags(operation)

    names::Array{Cstring}
    flags::Array{Cint}
    n_args::Cint

    result = ccall((:vips_object_get_args, _LIBNAME), 
        Cint, (Ptr{GObject}, Ptr{Array{Cstring}}, Ptr{Array{Cint}}, Ptr{Cint}),
        operation.pointer, Ref(names), Ref(flags), Ref(n_args))
    if result != 0 
        error("unable to get arguments from operation")
    end

    arguments = OrderedDict{String, Argument}();
    for i in 0:(n_args - 1)
        if flags[i] & CONSTRUCT
            # libvips uses '-' to separate parts of arg names, but we
            # need '_' for Julia
            name = replace(names[i], '-' => '_')
            gtype = get_gtype(operation, name)
            blurb = get_blurb(operation, name)
            arguments[name] = Argument(name, flags[i], gtype, blurb)
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

    # divide args into categories
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

            if !(argument.flags & DEPRECATED)
                push!(doc_optional_input, argument.name)
            end
        end

        if argument.flags & OUTPUT &&
            !(argument.flags & REQUIRED)
            push!(optional_output, argument.name)

            if !(argument.flags & _DEPRECATED)
                push!(doc_optional_output, argument.name)
            end
        end
    end

    Introspection(name, flags, description, arguments,
        required_input, optional_input, required_output, optional_output,
        doc_optional_input, doc_optional_output)
end
