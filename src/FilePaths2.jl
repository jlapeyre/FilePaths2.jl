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
export isabsolute, push, isseparator, absolute, filename, splitpath!
export MAIN_SEPARATOR, MAIN_SEPARATOR_STR

function notimplemented()
    error("Not implemented")
end

struct Path
    inner::String
end

_getinner(p::Path) = p.inner
# _ensure_string(p::Path) = p.inner
# _ensure_string(s::AbstractString) = s

# This is not pretty, but it allows more composition with
# functions that assume paths are strings.
function Base.:*(p1::Path, p2::Path)
    Path(p1.inner * p2.inner)
end

### Add methods for path API in Julia Base

# In Rust, `basename` is an alias for `file_name`
for func in (:abspath, :basename, :dirname, :expanduser, :contractuser, :normpath,
             :realpath)
    @eval Base.$func(p::Path) = Path($func(p.inner))
end

for func in (:isabspath, :isdirpath, :isempty)
    @eval Base.$func(p::Path) = $func(p.inner)
end

function Base.joinpath(paths::Union{AbstractVector{Path}, NTuple{<:Any, Path}})::Path
    Path(joinpath(map(_getinner, paths)))
end

function Base.joinpath(paths::Path...)::Path
    joinpath(paths)
end

function Base.relpath(path::Path, startpath::String=".")
    Path(relpath(path.inner, startpath))
end

function Base.relpath(path::Path, startpath::Path)
    relpath(path, startpath.inner)
end

function Base.splitdir(path::Path)
    (dir, file) = splitdir(path.inner)
    (Path(dir), Path(file))
end

function Base.splitdrive(path::Path)
    (drive, fpath) = splitdrive(path.inner)
    (Path(drive), Path(fpath))
end

import Base.Filesystem: _splitdir_nodrive

function _splitdir_nodrive(p::Path)
    (dir, base) = Base.Filesystem._splitdir_nodrive(p.inner)
    (Path(dir), Path(base))
end

# This is an exact copy of Base.Filesystem.splitpath(::String), xxcept for `out =
# Path[]`. Because of this detail, we have to either copy the code or do an extra
# allocation. We choose the former. We should add a function to the API that returns an
# iterator.
function Base.splitpath(p::Path)
    splitpath!(p, Path[])
end

# Empty `out` and split `p` into `out`.
function splitpath!(p::Path, out::Vector{Path})
    drive, p = splitdrive(p)
    empty!(out)
    isempty(p) && (pushfirst!(out,p))  # "" means the current directory.
    while !isempty(p)
        dir, base = _splitdir_nodrive(p)
        dir == p && (pushfirst!(out, dir); break)  # Reached root node.
        if !isempty(base)  # Skip trailing '/' in basename
            pushfirst!(out, base)
        end
        p = dir
    end
    if !isempty(drive)  # Tack the drive back on to the first element.
        out[1] = drive*out[1]  # Note that length(out) is always >= 1.
    end
    return out
end

# Neither the extension, nor the remainder is
# really a path. So return a `Tuple` of `String`.
# In fact, both are nearly alwasy, and probably exactly always
# legal paths. So we may want to return `Path`s.
# For now, return `String`s.
function Base.splitext(path::Path)
    splitext(path.inner)
end

# Leave this for the moment, as there is no obvious choice.
# Base.homedir()

###
### New API and supporting code. Often taken from Rust.
###

const MAIN_SEPARATOR_STR = Base.Filesystem.path_separator
const MAIN_SEPARATOR::Char = first(MAIN_SEPARATOR_STR)

# This is not equivalent to Rust's PathBuf
# But it's purpose overlaps at least in some cases.
struct PathBuf
    buf::IOBuffer
end

PathBuf() = PathBuf(IOBuffer())

# TODO: take care of separators.
Base.push!(pb::PathBuf, s::AbstractString) = write(pb.buf, s)

Path(pb::PathBuf) = Path(String(take!(pb.buf)))

Base.copy(p::Path) = Path(p.inner)

function isabsolute(p::Path)
    isabspath(p.inner)
end

# In Rust, this mutates `p`. In Julia we have
# to choose mutable or not. Perhaps there's a way
# to mutate the data. For now we return a new path
#
# We could make another struct just for building
# a path, like with an IOBuffer, and then convert
# to a Path.
function push(p::Path, p1::Path)
   Path(joinpath(p.inner, p1.inner))
end

function push(p::Path, p1::AbstractString)
   Path(joinpath(p.inner, p1))
end

function isverbatim(p::Path)
    notimplemented()
end

function isseparator(c::Char)
    notimplemented()
#    match(c, Base.Filesystem.path_separator_re)
end

function absolute(p::Path)
    Base.abspath(p)
end

# In Rust `file_name`. Follow Julia convention with `filename`.
function filename(p::Path)
    Base.basename(p)
end

end # module FilePaths2
