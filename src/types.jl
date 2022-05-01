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

# we have a hierarchy of abstract types, and all functions dispatch on these
#
# for each abstract tgype, there's a corresponding concrete type that 
# implements it

abstract type GObject end

# represents the glib type VipsObject
abstract type Object <: GObject end

# represent VipsOperation, VipsImage, VipsSource, VipsTarget
abstract type Operation <: Object end
abstract type Image <: Object end
abstract type Source <: Object end
abstract type Target <: Object end

mutable struct ConcreteGObject <: GObject
    pointer::Ptr{GObject}

    function ConcreteGObject(pointer::Ptr{GObject})
        gobject = new(pointer)
        finalizer(gobject -> unref(get_pointer(gobject)), gobject)
    end
end

mutable struct ConcreteObject <: Object
    pointer::Ptr{GObject}

    function ConcreteObject(pointer::Ptr{GObject})
        object = new(pointer)
        finalizer(object -> unref(get_pointer(object)), object)
    end
end

mutable struct ConcreteOperation <: Operation
    pointer::Ptr{GObject}

    function ConcreteOperation(pointer::Ptr{GObject})
        operation = new(pointer)
        finalizer(operation -> unref(get_pointer(operation)), operation)
    end
end

mutable struct ConcreteImage <: Image
    pointer::Ptr{GObject}

    function ConcreteImage(pointer::Ptr{GObject})
        image = new(pointer)
        finalizer(image -> unref(get_pointer(image)), image)
    end
end

mutable struct GParamSpec
    # opaque pointer used by GObject
    g_type_instance::Ptr{Cvoid}

    name::Cstring
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
