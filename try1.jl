#!/usr/bin/env julia

module Vips

    init_return = ccall((:vips_init, "libvips"), Int32, (String,), "")
    if init_return != 0
        error("unable to start libvips")
    end
    println("started libvips successfully!")

    version(flag) = ccall((:vips_version, "libvips"), Int32, (Int32,), flag)
    shutdown() = ccall((:vips_shutdown, "libvips"), Cvoid, ())
    error_exit(msg::String = "") = ccall((:vips_error_exit, "libvips"), 
        Cvoid, (String,), msg)

    version_string = join([string(version(x)) for x=0:2], ".")
    println("libvips version = $(version_string)")

    module GObjects

        # the base type for glib ... automatic ref and unref
        abstract type GObject end

        function ref(x::Ptr{GObject})
            ccall((:g_object_ref, :libvips), Cvoid, (Ptr{GObject},), x)
        end

        function unref(x::Ptr{GObject})
            ccall((:g_object_unref, :libvips), Cvoid, (Ptr{GObject},), x)
        end

    end

    module GValues

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
            ccall((:g_value_unset, :libvips), Cvoid, (Ptr{GValue},), 
                Ref(gvalue))
        end

        function init(gvalue, type)
            ccall((:g_value_init, :libvips), Cvoid, (Ptr{GValue}, Int64), 
                Ref(gvalue), type)
        end

        function set(gvalue, b::Bool)
            ccall((:g_value_set_boolean, :libvips), 
                Cvoid, (Ptr{GValue}, Cint), 
                Ref(gvalue), b)
        end

        function set(gvalue, i::Int64)
            ccall((:g_value_set_int64, :libvips), 
                Cvoid, (Ptr{GValue}, Clonglong), 
                Ref(gvalue), i)
        end

        function set(gvalue, i::UInt64)
            ccall((:g_value_set_uint64, :libvips), 
                Cvoid, (Ptr{GValue}, Culonglong), 
                Ref(gvalue), i)
        end

        function set(gvalue, f::Float64)
            ccall((:g_value_set_double, :libvips), 
                Cvoid, (Ptr{GValue}, Cdouble), 
                Ref(gvalue), f)
        end

        function set(gvalue, f::Float32)
            ccall((:g_value_set_float, :libvips), 
                Cvoid, (Ptr{GValue}, Cfloat), 
                Ref(gvalue), f)
        end

        function set(gvalue, s::String)
            ccall((:vips_value_set_ref_string, :libvips), 
                Cvoid, (Ptr{GValue}, Cstring), 
                Ref(gvalue), s)
        end

        function gtype(name)
            ccall((:g_type_from_name, :libvips), Int64, (Cstring,), name)
        end

        # some basic gtypes that libvips uses
        gboolean = gtype("gboolean")
        gint = gtype("gint")
        guint64 = gtype("guint64")
        gdouble = gtype("gdouble")
        gstr = gtype("gchararray")
        genum = gtype("GEnum")
        gflags = gtype("GFlags")
        gobject = gtype("GObject")
        image = gtype("VipsImage")
        array_int = gtype("VipsArrayInt")
        array_double = gtype("VipsArrayDouble")
        array_image = gtype("VipsArrayImage")
        refstr = gtype("VipsRefString")
        blob = gtype("VipsBlob")
        source = gtype("VipsSource")
        target = gtype("VipsTarget")

        function get(gvalue)
            if gvalue.gtype == gboolean
                ccall((:g_value_get_boolean, :libvips), 
                    Cint, (Ptr{GValue},), 
                    Ref(gvalue))
            elseif gvalue.gtype == gint
                ccall((:g_value_get_int, :libvips), 
                    Cint, (Ptr{GValue},), 
                    Ref(gvalue))
            elseif gvalue.gtype == guint64
                ccall((:g_value_get_uint64, :libvips), 
                    Culonglong, (Ptr{GValue},), 
                    Ref(gvalue))
            elseif gvalue.gtype == gdouble
                ccall((:g_value_get_double, :libvips), 
                    Cdouble, (Ptr{GValue},), 
                    Ref(gvalue))
            elseif gvalue.gtype == gstr
                string = ccall((:g_value_get_string, :libvips), 
                    Cstring, (Ptr{GValue},), 
                    Ref(gvalue))
                # TODO copy as a julia string
            end
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

value = Vips.GValues.GValue()
println("built object ", value)
value = nothing

println("running GC ...")
GC.gc()

println("done")

Vips.shutdown()
