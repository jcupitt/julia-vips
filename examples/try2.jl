#!/usr/bin/env julia


mutable struct GValue
    gtype::Int64
    data1::Int64
    data2::Int64

    function GValue()
        gvalue = new(0, 0, 0)
        finalizer(gvalue -> unset(gvalue), gvalue)
    end

end

macro define_set(fun, typ, ctyp)
    quote
        function set(gvalue, a::$(esc(typ)))
            ccall(
                ($(fun), :libvips), 
                Cvoid, 
                (Ptr{Int64}, $(esc(ctyp))), 
                Ref(gvalue), 
                a)
        end
    end
end

@define_set(:g_value_set_boolean, Bool, Cint)

