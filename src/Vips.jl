module Vips

    # we needs to generate a lot of the binding at runtime, unfortunately,
    # since the values of many things (eg. GType numbers) are only created
    # after vips_init()
    __precompile__(false)

    include("init.jl")
    include("types.jl")
    include("gvalue.jl")
    include("gobject.jl")
    include("image.jl")
    include("operation.jl")

end

