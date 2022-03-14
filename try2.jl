#!/usr/bin/env julia

mutable struct MyMutableStruct
    bar
    function MyMutableStruct(bar)
        println("in constructor")
        x = new(bar)
        finalizer(t -> println("finalizing $t."), x)
    end
end

thing = MyMutableStruct(12)

println("built object ", thing)

thing = Nothing

println("running GC ...")

GC.gc()

println("done")
