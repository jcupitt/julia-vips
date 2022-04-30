#=
#
# GObject support
#
=#

function get_pointer(gobject::GObject)
    gobject.pointer
end

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
# this will only work on VipsObject, but it's more convenient to define it here
function get_pspec(gobject, name)
    pspec::Ptr{GParamSpec}
    result = ccall((:vips_object_get_argument, _LIBNAME), 
        Cint, (Ptr{GObject}, Cstring, Ptr{GParamSpec}, Ptr{Cvoid}, Ptr{Cvoid}),
        get_pointer(gobject), name, Ref(pspec), C_NULL, C_NULL)
    if result != 0
        return nothing
    end

    return pspec
end

function get_blurb(pspec)
    str = ccall((:g_param_spec_get_blurb, _LIBNAME), 
        Cstring, (Ptr{GParamSpec},),
        pspec)

    unsafe_string(str)
end

function get_blurb(gobject, name)
    get_blurb(get_pspec(gobject, name))
end

function get_gtype(gobject, name)::GType
    pspec = get_pspec(gobject, name)
    if pspec == nothing
        return 0
    else
        return pspec.value_type
    end
end

function get(gobject, name)
    gtype = get_gtype(gobject, name)
    if gtype == 0
        error("Property $name not found")
    end

    gvalue = GValue()
    init(gvalue, gtype)
    ccall((:g_object_get_property, _LIBNAME), 
        Cvoid, (Ptr{GObject}, Ptr{GValue}), 
        get_pointer(gobject), Ref{gvalue})

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
        get_pointer(gobject), name, Ref{gvalue})
end
