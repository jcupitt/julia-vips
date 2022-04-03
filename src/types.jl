#=
#
# Types
#
=#

# ie. this is 32-bits on a 32-bit platform, 64 on a 64-bit one
const GType = Csize_t

mutable struct GValue
    gtype::GType

    data1::Int64
    data2::Int64

    function GValue()
        gvalue = new(0, 0, 0)
        finalizer(gvalue -> unset(gvalue), gvalue)
    end

end

# the base type for glib ... automatic ref and unref
abstract type GObject end

# the operation type subclasses GObject
mutable struct Operation 
    pointer::Ptr{GObject}

    function Operation(pointer::Ptr{GObject})
        ref(pointer)
        unref(pointer)

        operation = new(pointer)
        finalizer(operation -> unref(operation.pointer), operation)
    end
end

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

mutable struct GParamSpec
    # opaque pointer used by GObject
    g_type_instance::Ptr{Cvoid}

    name::Ptr{Cstring}
    flags::Cuint
    value_type::GType
    owner_type::GType

    # there are more, but they are private

    # no need for a constructor, we are given pointers to these things by
    # GObject, we never make or free them ourselves
end

# values for VipsArgumentFlags
const REQUIRED = 1
const CONSTRUCT = 2
const SET_ONCE = 4
const SET_ALWAYS = 8
const INPUT = 16
const OUTPUT = 32
const DEPRECATED = 64
const MODIFY = 128

# everything we discover about an operation argument during introspection
struct Argument
    name::String
    flags::Int
    gtype::GType
    blurb::String

end

# for VipsOperationFlags
const OPERATION_DEPRECATED = 8

# everything we discover about an operation during introspection
struct Introspection
    name::String
    flags::Int
    description::String
    arguments::OrderedDict{String, Argument}

    required_input::Vector{String}
    optional_input::Vector{String}
    required_output::Vector{String}
    optional_output::Vector{String}

    doc_optional_input::Vector{String}
    doc_optional_output::Vector{String}

end
