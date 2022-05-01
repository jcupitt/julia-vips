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

    # we pass pointers to null pointers, which get_args will overwrite with
    # pointers to an array of strings and an array of flags
    cnames = Ref{Ptr{Cstring}}(C_NULL)
    cflags = Ref{Ptr{Cint}}(C_NULL)
    cn_args = Ref{Cint}(0)

    result = ccall((:vips_object_get_args, _LIBNAME), 
        Cint, 
        (Ptr{GObject}, Ref{Ptr{Cstring}}, Ref{Ptr{Cint}}, Ref{Cint}),
        get_pointer(operation), cnames, cflags, cn_args)
    if result != 0 
        error("unable to get arguments from operation")
    end

    n_args = cn_args[]
    flags = unsafe_wrap(Vector{Cint}, cflags[], n_args)

    unsafe_names = unsafe_wrap(Vector{Cstring}, cnames[], n_args)
    names = []
    for i in 1:n_args
        push!(names, unsafe_string(unsafe_names[i]))
    end

    #    println("Introspection after:")
    #    println("n_args = ", n_args)
    #    println("flags = ", flags)
    #    println("names = ", names)

    arguments = OrderedDict{String, Argument}();
    for i in 1:n_args
        if (flags[i] & CONSTRUCT) != 0
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

    # sort args into categories
    for argument in arguments
        if (argument.flags & INPUT) != 0 &&
            (argument.flags & REQUIRED) != 0 &&
            (argument.flags & DEPRECATED) == 0
            push!(required_input, argument.name)

            # required inputs which we MODIFY are also required outputs
            if (argument.flags & MODIFY) != 0
                push!(required_output, argument.name)
            end
        end

        if (argument.flags & OUTPUT) != 0 &&
            (argument.flags & REQUIRED) != 0 &&
            (argument.flags & DEPRECATED) == 0
            push!(required_output, argument.name)
        end

        # deprecated optional args get on to the main arg lists, but are
        # filtered from the documented set
        if (argument.flags & INPUT) != 0 &&
            (argument.flags & REQUIRED) == 0
            push!(optional_input, argument.name)

            # doc args omit deprecated
            if (argument.flags & DEPRECATED) == 0
                push!(doc_optional_input, argument.name)
            end
        end

        if (argument.flags & OUTPUT) != 0 &&
            (argument.flags & REQUIRED) == 0
            push!(optional_output, argument.name)

            # doc args omit deprecated
            if (argument.flags & DEPRECATED) == 0
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
