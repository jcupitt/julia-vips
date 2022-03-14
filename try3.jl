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
            ccall((:g_object_ref, "libvips"), Cvoid, (Ptr{GObject},), x)
        end

        function unref(x::Ptr{GObject})
            ccall((:g_object_unref, "libvips"), Cvoid, (Ptr{GObject},), x)
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
                # finalizer(image, image -> unref(image.pointer))
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

    end

end

# image = Vips.Images.new_from_file("/home/john/pics/xxxx")
image = Vips.Images.new_from_file("/home/john/pics/k2.jpg")

println("built object ", image)

image = nothing

println("running GC ...")

GC.gc()

println("done")

Vips.shutdown()
