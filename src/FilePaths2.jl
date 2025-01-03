module FilePaths2

## Modeled on Rust's stdlib::path
##
## It's not clear immediately how or if to implement
## some functions/methods from stdlib::path.
## Some of these functions are included here and just
## throw an error.
##
## The semantics of Julia and Rust are different enough
## that is is difficult to make a direct translation.

export Path, PathBuf
export splitpath!

export isabsolute, isrelative, push, isseparator, absolute, filename,
    extension, fileprefix, hasroot, @p_str
export MAIN_SEPARATOR, MAIN_SEPARATOR_STR

# Not implemented yet
export parent

function notimplemented()
    error("Not implemented")
end

include("paths.jl")
include("io.jl")

end # module FilePaths2
