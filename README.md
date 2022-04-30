# julia-vips

Messing about with julia to see what a libvips binding might look like.

Strategy:

- We have a hierarchy of abstract types to represent the libvips type 
  hierarchy

- For each abstract type, there's a concrete `mutable struct` that subtypes
  (implements) it

- We never use `object.name`, we always use getters and setters

- We dispatch everything on the abstract types (except the implementations of
  the getters and setters, which use the concrete types)

- Result: OO-style inheritance for the libvips class hierarchy, hopefully

Try:

```
$ ./test-drive.jl
  Activating new project at `/tmp/jl_zaxnGQ`
  Activating project at `~/GIT/julia-vips`
    Updating registry at `~/.julia/registries/General.toml`
   Resolving package versions...
  No Changes to `~/GIT/julia-vips/Project.toml`
  No Changes to `~/GIT/julia-vips/Manifest.toml`
started libvips successfully!
libvips version = 8.13.0
built object Vips.ConcreteImage(Ptr{Vips.GObject} @0x000000000289e000)
width = 1450

GValue tests:
assigning bool:
init done
gvalue = Vips.GValue(0x0000000000000014, 1, 0)
get value = 1

assigning refstr:
init done
gvalue = Vips.GValue(0x00000000025161e0, 37741760, 0)
get value = hello!
running GC ...
done
memory: high-water mark 0 bytes
```
