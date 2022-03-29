#!/usr/bin/env julia

module Vips

#=
#
# libvips startup
#
=#

const _LIBNAME = :libvips

init_return = ccall((:vips_init, _LIBNAME), 
    Int32, (String,), 
    "")
if init_return != 0
    error("unable to start libvips")
end
println("started libvips successfully!")

version(flag) = ccall((:vips_version, _LIBNAME), 
    Int32, (Int32,), 
    flag)
shutdown() = ccall((:vips_shutdown, _LIBNAME), 
    Cvoid, ())
error_exit(msg::String = "") = ccall((:vips_error_exit, _LIBNAME), 
    Cvoid, (String,), 
    msg)

const VIPS_VERSION = VersionNumber([version(i) for i=0:2]...)
println("libvips version = $(VIPS_VERSION)")

#=
#
# Types
#
=#

mutable struct GValue
    gtype::Int64
    data1::Int64
    data2::Int64

    function GValue()
        gvalue = new(0, 0, 0)
        finalizer(gvalue -> unset(gvalue), gvalue)
    end

end

# the base type for glib ... automatic ref and unref
abstract type GObject end

# the image type subclasses GObject
mutable struct Image 
    pointer::Ptr{GObject}

    function Image(pointer::Ptr{GObject})
        ref(pointer)
        unref(pointer)

        image = new(pointer)
        finalizer(image -> unref(image.pointer), image)
    end
end

#=
#
# GObject support
#
=#

function ref(x::Ptr{GObject})
    ccall((:g_object_ref, _LIBNAME), 
        Cvoid, (Ptr{GObject},), 
        x)
end

function unref(x::Ptr{GObject})
    ccall((:g_object_unref, _LIBNAME), 
        Cvoid, (Ptr{GObject},), 
        x)
end

#=
#
# GValue support
#
=#

function gtype(name)
    ccall((:g_type_from_name, _LIBNAME), 
        Int64, (Cstring,), 
        name)
end

for (nm, typ) in (
    (:GBOOLEAN,     "gboolean"),
    (:GINT,         "gint"),
    (:GINT64,       "gint64"),
    (:GUINT64,      "guint64"),
    (:GFLOAT,       "gfloat"),
    (:GDOUBLE,      "gdouble"),
    (:GSTR,         "gchararray"),
    (:GENUM,        "GEnum"),
    (:GFLAGS,       "GFlags"),
    (:GOBJECT,      "GObject"),
    (:IMAGE,        "VipsImage"),
    (:ARRAY_INT,    "VipsArrayInt"),
    (:ARRAY_DOUBLE, "VipsArrayDouble"),
    (:ARRAY_IMAGE,  "VipsArrayImage"),
    (:REFSTR,       "VipsRefString"),
    (:BLOB,         "VipsBlob"),
    (:SOURCE,       "VipsSource"),
    (:TARGET,       "VipsTarget"))

    @eval const $nm = gtype($typ) 
end

function unset(gvalue::GValue)
    ccall((:g_value_unset, _LIBNAME), 
        Cvoid, (Ptr{GValue},), 
        Ref(gvalue))
end

function init(gvalue, type)
    ccall((:g_value_init, _LIBNAME), 
        Cvoid, (Ptr{GValue}, Int64), 
        Ref(gvalue), type)
end

function enum_from_nick(gtype, name)
    ccall((:vips_enum_from_nick, _LIBNAME), 
        Clonglong, (Clonglong, Cstring), 
        gtype, name)
end

# turn a string into a gtype, ready to be passed into libvips
to_enum(gtype, value::AbstractString) = enum_from_nick(gtype, value)
to_enum(gtype, value) = value 

# turn an enum int back into a string
function from_enum(gtype, value)
    pointer = enum_nick(gtype, value)
    if pointer == C_NULL
        error("name not in enum")
    end

    unsafe_string(value)
end

function enum_nick(gtype, value)
    ccall((:vips_enum_nick, _LIBNAME), 
        Cstring, (Clonglong, Clonglong), 
        gtype, value)
end

# set_type() uses a fundamental gtype (eg. "enum") and a specific type (eg.
# "enum BandFormat") to set a gvalue
for (fun, gtyp, ctyp) in (
    ("g_value_set_boolean",       :GBOOLEAN, Cint),
    ("g_value_set_int64",         :GINT64,   Clonglong),
    ("g_value_set_uint64",        :GUINT64,  Culonglong),
    ("g_value_set_double",        :GDOUBLE,  Cdouble),
    ("g_value_set_float",         :GFLOAT,   Cfloat),
    ("g_value_set_enum",          :GENUM,    Cint),
    ("g_value_set_flags",         :GFLAGS,   Cint),
    ("g_value_set_string",        :GSTR,     Cstring),
    ("g_value_set_object",        :GOBJECT,  Ptr{GObject}),
    ("vips_value_set_ref_string", :REFSTR,   Cstring))

    @eval set_type(gvalue, ::Any, ::Val{$gtyp}, value) = ccall(($fun, _LIBNAME),
        Cvoid, (Ptr{GValue}, $ctyp), 
        Ref(gvalue), value)

end

function set_type(gvalue, ::Any, ::Val{GENUM}, gtype, value)
    value = to_enum(gtype, value)
    set_type(gvalue, Any, Val(gtype), value)
end

function set_type(gvalue, ::Val{GOBJECT}, gtype, value)
    set_type(gvalue, Any, Val(GOBJECT), value.pointer)
end

function set_type(gvalue, ::Any, ::Val{ARRAY_INT}, value)
    # TODO
end

function set_type(gvalue, ::Any, ::Val{ARRAY_DOUBLE}, value)
    # TODO
end

function set_type(gvalue, ::Any, ::Val{ARRAY_IMAGE}, value)
    # TODO
end

function set_type(gvalue, ::Any, ::Val{BLOB}, value)
    # TODO
end

function type_fundamental(gtype)
    ccall((:g_type_fundamental, _LIBNAME), 
        Clonglong, (Clonglong,), 
        gtype)
end

function set(gvalue, value)
    gtype = gvalue.gtype
    fundamental = type_fundamental(gtype)
    set_type(gvalue, Val(fundamental), Val(gtype), value)
end

for (fun, gtyp, ctyp) in (
    ("g_value_get_boolean", :GBOOLEAN, Cint),
    ("g_value_get_int",     :GINT,     Cint),
    ("g_value_get_int64",   :GINT64,   Clonglong),
    ("g_value_get_uint64",  :GUINT64,  Culonglong),
    ("g_value_get_float",   :GFLOAT,   Cfloat),
    ("g_value_get_double",  :GDOUBLE,  Cdouble),
    ("g_value_get_enum",    :GENUM,    Cint),
    ("g_value_get_flags",   :GFLAGS,   Cint),
    ("g_value_get_object",  :GOBJECT,  Ptr{GObject}),
    ("g_value_get_float",   :GFLOAT,   Cfloat))

    @eval get_type(gvalue, ::Any, ::Val{$gtyp}) = ccall(($fun, _LIBNAME), 
        $ctyp, (Ptr{GValue},), 
        Ref(gvalue))
end

# string gets needs an extra unsafe_string() on the output to get a julia
# string back
for (fun, gtyp) in (
    ("vips_value_get_ref_string",  :REFSTR),
    ("g_value_get_string",  :GSTR))

    @eval begin
        function get_type(gvalue, ::Any, ::Val{$gtyp}) 
            str = ccall(($fun, _LIBNAME), 
                Cstring, (Ptr{GValue},), 
                Ref(gvalue))

            unsafe_string(str)
        end
    end
end

function get_type(gvalue, ::Val{GENUM}, gtype)
    value = get_type(gvalue, Any, Val(GENUM))
    from_enum(gtype, value)
end

function get_type(gvalue, ::Val{GFLAGS}, gtype)
    get_type(gvalue, Any, Val(GFLAGS))
end

function get_type(gvalue, ::Val{GOBJECT}, ::Val{IMAGE})
    pointer = get_type(gvalue, Any, Val(GOBJECT))
    ref(pointer)
    Image(pointer)
end

function get_type(gvalue, ::Any, ::Val{ARRAY_INT})
    # TODO
end

function get_type(gvalue, ::Any, ::Val{ARRAY_DOUBLE})
    # TODO
end

function get_type(gvalue, ::Any, ::Val{ARRAY_IMAGE})
    # TODO
end

function get_type(gvalue, ::Any, ::Val{BLOB})
    # TODO
end

function get(gvalue)
    gtype = gvalue.gtype
    fundamental = type_fundamental(gtype)
    get_type(gvalue, Val(fundamental), Val(gtype))
end

#=
#
# libvips image support
#
=#

function new_from_file(filename::String)::Image
    pointer = ccall((:vips_image_new_from_file, "libvips"), 
        Ptr{GObject}, (Cstring, Ptr{Cvoid}), 
        filename, C_NULL)
    if pointer == C_NULL
        error_exit()
    end
    Image(pointer)
end

function width(image::Image)::Int32
    ccall((:vips_image_get_width, "libvips"), 
        Int32, (Ptr{GObject},), 
        image.pointer)
end

end # of Vips module

image = Vips.new_from_file("/home/john/pics/k2.jpg")
println("built object ", image)
println("width = ", Vips.width(image))
image = nothing

println()
println("GValue tests:")
gvalue = Vips.GValue()

println("assigning bool:")
gvalue = Vips.GValue()
Vips.init(gvalue, Vips.GBOOLEAN)
Vips.set(gvalue, true)
b = Vips.get(gvalue)
println("gvalue = ", gvalue)
println("get value = ", b)

println("assigning refstr:")
gvalue = Vips.GValue()
Vips.init(gvalue, Vips.REFSTR)
Vips.set(gvalue, "hello!")
s = Vips.get(gvalue)
println("gvalue = ", gvalue)
println("get value = ", s)

gvalue = nothing

println("running GC ...")
GC.gc()

println("done")

Vips.shutdown()
