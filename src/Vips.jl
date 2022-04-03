module Vips

    # we needs to generate most of the binding at runtime, unfortunately,
    # since the values of many constants (eg. GType numbers) are only set
    # in vips_init()
    __precompile__(false)

    using OrderedCollections

    include("init.jl")
    include("types.jl")
    include("gvalue.jl")
    include("gobject.jl")
    include("image.jl")
    include("introspection.jl")
    include("operation.jl")

end

