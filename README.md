# julia-vips

Messing about with julia to see what a libvips binding might look like.

Try:

```
$ ./test-drive.jl ~/pics/k2.jpg
  Activating new project at `/tmp/jl_3Kd57G`
  Activating project at `~/GIT/julia-vips`
started libvips successfully!
libvips version = 8.13.0
built object Vips.Image(Ptr{Vips.GObject} @0x0000000001787010)
width = 1450

GValue tests:
assigning bool:
init done
gvalue = Vips.GValue(0x0000000000000014, 1, 0)
get value = 1

assigning refstr:
init done
gvalue = Vips.GValue(0x00000000015f3d60, 24843088, 0)
get value = hello!
running GC ...
done
memory: high-water mark 0 bytes
```
