#=
#
# VipsObject support
#
=#

function get_pointer(object::Object)
    object.pointer
end

function set_string(object, string_option)
    ccall((:vips_object_set_from_string, _LIBNAME), 
        Cvoid, (Ptr{GObject}, Cstring),
        get_pointer(object), string_options)
end

function get_description(object)
    str = ccall((:vips_object_get_description, _LIBNAME), 
        Cstring, (Ptr{GObject},),
        get_pointer(object))

    unsafe_string(str)
end
