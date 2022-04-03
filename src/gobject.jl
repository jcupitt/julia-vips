#=
#
# GObject support
#
=#

function ref(pointer::Ptr{GObject})
    ccall((:g_object_ref, _LIBNAME), 
        Cvoid, (Ptr{GObject},), 
        pointer)
end

function unref(pointer::Ptr{GObject})
    ccall((:g_object_unref, _LIBNAME), 
        Cvoid, (Ptr{GObject},), 
        pointer)
end

# this is horribly slow, cache this if possible
function get_pspec(pointer::Ptr{GObject}, name)::Ptr{GParamSpec}
    pspec::Ptr{GParamSpec}
    result = ccall((:vips_object_get_argument, _LIBNAME), 
        Cint, (Ptr{GObject}, Cstring, Ptr{GParamSpec}, Ptr{Cvoid}, Ptr{Cvoid}),
        pointer, name, Ref(pspec), C_NULL, C_NULL)
    if result != 0
        return nothing
    end

    return pspec
end

get_pspec(gobject::GObject, name) = get_pspec(gobject.pointer, name)

function get_blurb(pspec)::String
    ccall((:g_param_spec_get_blurb, _LIBNAME), 
        Cstring, (Ptr{GParamSpec},),
        pspec)
end

function get_blurb(gobject, name)::String
    pspec = get_pspec(gobject, name)
    get_blurb(pspec)
end

function get_gtype(pointer::Ptr{GObject}, name)::GType
    pspec = get_pspec(pointer, name)
    if pspec == nothing
        return 0
    else
        return pspec.value_type
    end
end

get_gtype(gobject::GObject, name) = get_gtype(gobject.pointer, name)

function get(gobject, name)
    gtype = get_gtype(gobject, name)
    if gtype == 0
        error("Property $name not found")
    end

    gvalue = GValue()
    init(gvalue, gtype)
    ccall((:g_object_get_property, _LIBNAME), 
        Cvoid, (Ptr{GObject}, Ptr{GValue}), 
        gobject.pointer, Ref{gvalue})

    get(gvalue)
end

function set(gobject, name, value)
    gtype = get_gtype(gobject, name)
    if gtype == 0
        error("Property $name not found")
    end

    gvalue = GValue()
    init(gvalue, gtype)
    set(gvalue, value)
    ccall((:g_object_set_property, _LIBNAME), 
        Cvoid, (Ptr{GObject}, Cstring, Ptr{GValue}), 
        gobject.pointer, name, Ref{gvalue})
end

function set_string(gobject, string_option)
    ccall((:vips_object_set_from_string, _LIBNAME), 
        Cvoid, (Ptr{GObject}, Cstring),
        gobject.pointer, string_options)
end

function get_description(gobject)
    ccall((:vips_object_get_description, _LIBNAME), 
        Cstring, (Ptr{GObject},),
        gobject.pointer)
end
