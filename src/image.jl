#=
#
# libvips image support
#
=#

function get_pointer(image::Image)
    image.pointer
end

function new_from_file(filename::String)::Image
    pointer = ccall((:vips_image_new_from_file, _LIBNAME), 
        Ptr{GObject}, (Cstring, Ptr{Cvoid}), 
        filename, C_NULL)
    if pointer == C_NULL
        error_exit()
    end
    ConcreteImage(pointer)
end

function width(image::Image)
    ccall((:vips_image_get_width, _LIBNAME), 
        Int32, (Ptr{GObject},), 
        get_pointer(image))
end

function copy_memory(image::Image)
    pointer = ccall((:vips_image_copy_memory, _LIBNAME), 
        Ptr{GObject}, (Ptr{GObject},), 
        get_pointer(image))
    ConcreteImage(pointer)
end
