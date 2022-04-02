#=
#
# Operation class
#
=#

function Operation(name::String)
    pointer = ccall((:vips_operation_new, _LIBNAME), 
        Ptr{GObject}, (Cstring,), 
        name)
    if pointer == C_NULL
        error_exit()
    end
    Operation(pointer)
end

function imageize(match_image, value)
    # TODO
    
    return value
end

# set a parameter on an operation
function set(operation, name, flags, match_image, value)
    if match_image
        gtype = get_typeof(operation, name)

        if gtype == IMAGE
            value = imageize(match_image, value)
        elseif gtype == ARRAY_IMAGE
            value = [imageize(match_image, x) for x in value]
        end
    end

    # MODIFY arguments must be copied first
    if flags & MODIFY
        value = (copy_memory ∘ copy)(value)
    end

    set(operation.pointer, name, value)
end

# walk an operation, building an introspection object
function introspect(name)
end

