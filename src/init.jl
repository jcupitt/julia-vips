#=
#
# Initialization
#
=#

const _LIBNAME = :libvips

version(flag) = ccall((:vips_version, _LIBNAME), 
    Int32, (Int32,), 
    flag)
shutdown() = ccall((:vips_shutdown, _LIBNAME), 
    Cvoid, ())
error_exit(msg::String = "") = ccall((:vips_error_exit, _LIBNAME), 
    Cvoid, (String,), 
    msg)

init_return = ccall((:vips_init, _LIBNAME), 
    Int32, (String,), 
    "")
if init_return != 0
    error("unable to start libvips")
end
println("started libvips successfully!")

const VIPS_VERSION = VersionNumber([version(i) for i=0:2]...)
println("libvips version = $(VIPS_VERSION)")

