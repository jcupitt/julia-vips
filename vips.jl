#!/usr/bin/env julia

module Vips
    
    const _LIB_FP = :libvips

    init_return = ccall((:vips_init, _LIB_FP), Int32, (String,), "")
    if init_return != 0
        error("unable to start libvips")
    end
    println("started libvips successfully!")

    version(flag) = ccall((:vips_version, _LIB_FP), Int32, (Int32,), flag)
    shutdown() = ccall((:vips_shutdown, _LIB_FP), Cvoid, ())
    error_exit(msg::String = "") = ccall((:vips_error_exit, _LIB_FP), 
        Cvoid, (String,), msg)
    
    const VIPS_VERSION = VersionNumber([version(i) for i=0:2]...)
    println("libvips version = $(VIPS_VERSION)")

    module GObjects

        import ..Vips: _LIB_FP

        # the base type for glib ... automatic ref and unref
        abstract type GObject end

        function ref(x::Ptr{GObject})
            ccall((:g_object_ref, _LIB_FP), Cvoid, (Ptr{GObject},), x)
        end

        function unref(x::Ptr{GObject})
            ccall((:g_object_unref, _LIB_FP), Cvoid, (Ptr{GObject},), x)
        end

    end

    module GValues

        import ..Vips: _LIB_FP

        mutable struct GValue
            g_type::Int64
            data1::Int64
            data2::Int64

            function GValue()
                gvalue = new(0, 0, 0)
                finalizer(gvalue -> unset(gvalue), gvalue)
            end

        end

        function unset(gvalue::GValue)
            ccall((:g_value_unset, _LIB_FP), Cvoid, (Ptr{GValue},), 
                Ref(gvalue))
        end

        function init(gvalue, type)
            ccall((:g_value_init, _LIB_FP), Cvoid, (Ptr{GValue}, Int64), 
                Ref(gvalue), type)
        end

        for (fun, typ, ctyp) in (
            (:g_value_set_boolean,       Bool,    Cint),
            (:g_value_set_int64,         Int64,   Clonglong),
            (:g_value_set_uint64,        UInt64,  Culonglong),
            (:g_value_set_double,        Float64, Cdouble),
            (:g_value_set_float,         Float32, Cfloat),
            (:vips_value_set_ref_string, String,  Cstring))

            @eval set(gvalue, a::$typ) = ccall(
                ($fun, _LIB_FP), 
                Cvoid, 
                (Ptr{GValue}, $ctyp), 
                Ref(gvalue), 
                a)
        end

        function gtype(name)
            ccall((:g_type_from_name, _LIB_FP), Int64, (Cstring,), name)
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
                ($fun, _LIB_FP), 
                $ctyp, 
                (Ptr{GValue},), 
                Ref(gvalue))
        end

        function get(gvalue)
            get_type(gvalue, gvalue.gtype)
        end

    end

    module Images

        import ..GObjects: GObject, ref, unref
        import ..Vips: error_exit

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

    end

end

# image = Vips.Images.new_from_file("/home/john/pics/xxxx")
image = Vips.Images.new_from_file("/home/john/pics/k2.jpg")
println("built object ", image)
println("width = ", Vips.Images.width(image))
image = nothing

gvalue = Vips.GValues.GValue()
println("built object ", gvalue)

Vips.GValues.set(gvalue, true)
println("assigned true ", gvalue)

gvalue = nothing

println("running GC ...")
GC.gc()

println("done")

Vips.shutdown()
