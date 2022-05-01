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
    cpspec = Ref{Ptr{GParamSpec}}(C_NULL)
    cargument_class = Ref{Ptr{Cvoid}}(C_NULL)
    cargument_instance = Ref{Ptr{Cvoid}}(C_NULL)

    println("get_pspec:")
    println("before:")
    println("cpspec[] = ", cpspec[])

    structinfo(T) = [(fieldoffset(T,i), fieldname(T,i), fieldtype(T,i)) for i = 1:fieldcount(T)];
    println(structinfo(GParamSpec))

    result = ccall((:vips_object_get_argument, _LIBNAME), 
        Cint, (Ptr{GObject}, Cstring, 
               Ref{Ptr{GParamSpec}}, Ref{Ptr{Cvoid}}, Ref{Ptr{Cvoid}}),
        get_pointer(gobject), name, cpspec, cargument_class, cargument_instance)
    if result != 0
        return nothing
    end

    println("after:")
    println("cpspec[] = ", cpspec[])

    println("calling unsafe_wrap:")

    pspec = unsafe_wrap(Vector{GParamSpec}, cpspec[], 1)

    println("after:")

#    str = unsafe_string(pspec[1].name)
#    println("pspec[1].name = ",  str)

    println("pspec[1].flags = ", pspec[1].flags)
    println("pspec[1].value_type = ", pspec[1].value_type)
    println("pspec[1].owner_type = ", pspec[1].owner_type)

    return pspec[1]
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
