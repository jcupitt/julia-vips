#!/usr/bin/env julia

import Pkg

tempdir = mktempdir()
Pkg.activate(tempdir)
Pkg.activate(".")
Pkg.add("OrderedCollections")

# test-drive the vips module

import Vips

image = Vips.new_from_file("/home/john/pics/k2.jpg")
println("built object ", image)
println("width = ", Vips.width(image))
image = nothing

println()
println("GValue tests:")
gvalue = Vips.GValue()

println("assigning bool:")
gvalue = Vips.GValue()
Vips.init(gvalue, Vips.GBOOLEAN)
Vips.set(gvalue, true)
b = Vips.get(gvalue)
println("gvalue = ", gvalue)
println("get value = ", b)
Vips.unset(gvalue)
println()

println("assigning refstr:")
gvalue = Vips.GValue()
Vips.init(gvalue, Vips.REFSTR)
Vips.set(gvalue, "hello!")
s = Vips.get(gvalue)
println("gvalue = ", gvalue)
println("get value = ", s)
Vips.unset(gvalue)

gvalue = nothing

println("running GC ...")
GC.gc()

println("done")

Vips.shutdown()

