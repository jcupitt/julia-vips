#!/usr/bin/env julia

module Vips

#=
#
# libvips startup
#
=#

const _LIBNAME = :libvips

init_return = ccall((:vips_init, _LIBNAME), Int32, (String,), "")
if init_return != 0
    error("unable to start libvips")
end
println("started libvips successfully!")

version(flag) = ccall((:vips_version, _LIBNAME), Int32, (Int32,), flag)
shutdown() = ccall((:vips_shutdown, _LIBNAME), Cvoid, ())
error_exit(msg::String = "") = ccall((:vips_error_exit, _LIBNAME), 
    Cvoid, (String,), msg)

const VIPS_VERSION = VersionNumber([version(i) for i=0:2]...)
println("libvips version = $(VIPS_VERSION)")

#=
#
# GObject support
#
=#

# the base type for glib ... automatic ref and unref
abstract type GObject end

function ref(x::Ptr{GObject})
    ccall((:g_object_ref, _LIBNAME), Cvoid, (Ptr{GObject},), x)
end

function unref(x::Ptr{GObject})
    ccall((:g_object_unref, _LIBNAME), Cvoid, (Ptr{GObject},), x)
end

#=
#
# GValue support
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

function unset(gvalue::GValue)
    ccall((:g_value_unset, _LIBNAME), Cvoid, (Ptr{GValue},), 
        Ref(gvalue))
end

function init(gvalue, type)
    ccall((:g_value_init, _LIBNAME), Cvoid, (Ptr{GValue}, Int64), 
        Ref(gvalue), type)
end

macro define_set(fun, typ, ctyp)
    quote
        function $(esc(:set))($(esc(:gvalue)), $(esc(:a))::$(esc(typ)))
            ccall(
                ($fun, _LIBNAME), 
                Cvoid, 
                (Ptr{GValue}, $ctyp), 
                Ref($(esc(:gvalue))), 
                a)
        end
    end
end

# println(@macroexpand @define_set(:g_value_set_boolean, Bool, Cint))

@define_set(:g_value_set_boolean,       Bool,    Cint)
@define_set(:g_value_set_int64,         Int64,   Clonglong)
@define_set(:g_value_set_uint64,        UInt64,  Culonglong)
@define_set(:g_value_set_double,        Float64, Cdouble)
@define_set(:g_value_set_float,         Float32, Cfloat)
@define_set(:vips_value_set_ref_string, String,  Cstring)

#=

    fails with:

        UndefVarError: g_value_set_boolean not defined

    ie. the symbol is being misinteropreted as an identifier

for (fun, typ, ctyp) in (
    (:g_value_set_boolean,       Bool,    Cint),
    (:g_value_set_int64,         Int64,   Clonglong),
    (:g_value_set_uint64,        UInt64,  Culonglong),
    (:g_value_set_double,        Float64, Cdouble),
    (:g_value_set_float,         Float32, Cfloat),
    (:vips_value_set_ref_string, String,  Cstring))

    @eval set(gvalue, a::$typ) = 
        ccall(($fun, _LIBNAME), Cvoid, (Ptr{GValue}, $ctyp), Ref(gvalue), a)
end

=#

function gtype(name)
    ccall((:g_type_from_name, _LIBNAME), Int64, (Cstring,), name)
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

for (fun, gtyp, ctyp) in (
    (:g_value_get_boolean, :GBOOLEAN, Cint),
    (:g_value_get_int64,   :GINT64,   Clonglong),
    (:g_value_get_uint64,  :GUINT64,  Culonglong),
    (:g_value_get_double,  :GDOUBLE,  Cdouble),
    (:g_value_get_float,   :GFLOAT,   Cfloat),
    (:g_value_get_string,  :GSTR,     Cstring))

    @eval get_type(gvalue, ::Val{$gtyp}) = ccall(
        # ($fun, _LIBNAME), 
        (:g_value_get_boolean, _LIBNAME), 
        $ctyp, 
        (Ptr{GValue},), 
        Ref(gvalue))
end

function get(gvalue)
    println("gvalue.gtype = ", gvalue.gtype)
    println("GBOOLEAN = ", GBOOLEAN)
    get_type(gvalue, Val(gvalue.gtype))
end

#=
#
# libvips image support
#
=#

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

gvalue = Vips.GValue()
println("built object ", gvalue)

Vips.init(gvalue, Vips.GBOOLEAN)
Vips.set(gvalue, true)
println("assigned true ", gvalue)

b = Vips.get(gvalue)
println("read value ", b)

gvalue = nothing

println("running GC ...")
GC.gc()

println("done")

Vips.shutdown()
