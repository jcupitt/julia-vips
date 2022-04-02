#=
#
# libvips image support
#
=#

function new_from_file(filename::String)::Image
    pointer = ccall((:vips_image_new_from_file, _LIBNAME), 
        Ptr{GObject}, (Cstring, Ptr{Cvoid}), 
        filename, C_NULL)
    if pointer == C_NULL
        error_exit()
    end
    Image(pointer)
end

function width(image::Image)::Int32
    ccall((:vips_image_get_width, _LIBNAME), 
        Int32, (Ptr{GObject},), 
        image.pointer)
end

