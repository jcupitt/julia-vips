#=
#
# Operation object
#
=#

function Operation(name::String)
    pointer = ccall((:vips_operation_new, _LIBNAME), 
        Ptr{GObject}, (Cstring,), 
        name)
    if pointer == C_NULL
        error_exit()
    end
    ConcreteOperation(pointer)
end

function get_pointer(operation::Operation)
    operation.pointer
end

function imageize(match_image, value)
    # TODO
    
    return value
end

# set a parameter on an operation
function set(operation, name, flags, match_image, value)
    if match_image
        gtype = get_gtype(operation, name)

        if gtype == IMAGE
            value = imageize(match_image, value)
        elseif gtype == ARRAY_IMAGE
            value = [imageize(match_image, x) for x in value]
        end
    end

    # MODIFY arguments must be copied first
    if flags & MODIFY
        value = copy_memory(value)
    end

    set(operation, name, value)
end

function get_flags(operation)
    ccall((:vips_operation_get_flags, _LIBNAME), 
        Int, (Ptr{GObject},),
        get_pointer(operation))
end

