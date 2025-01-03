struct Path
    inner::String
end

macro p_str(inner)
    Path(inner)
end

_getinner(p::Path) = p.inner
# _ensure_string(p::Path) = p.inner
# _ensure_string(s::AbstractString) = s

Base.String(path::Path) = path.inner

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

function Base.splitpath(p::Path)
    splitpath!(p, Path[])
end

# Empty `out` and split `p` into `out`.
# This is an exact copy of Base.Filesystem.splitpath(::String), except for `out =
# Path[]`. Because of this detail, we have to either copy the code or do an extra
# allocation. We choose the former. We should add a function to the API that returns an
# iterator.
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
# In fact, both are nearly always, and probably exactly always
# legal paths. So we may want to return `Path`s.
# For now, return `String`s.
# NB. Rust returns `&OsStr`, not `Path`.
# Rust has no equivalent of `splitext`, but rather
# `extension` and `file_prefix`.
function Base.splitext(path::Path)
    splitext(path.inner)
end

# Leave this for the moment, as there is no obvious choice.
# Base.homedir()

###
### Additional API and supporting code. Often taken from Rust.
###

const MAIN_SEPARATOR_STR::String = Base.Filesystem.path_separator
const MAIN_SEPARATOR::Char = first(MAIN_SEPARATOR_STR)

# This is not equivalent to Rust's PathBuf
# But it's purpose overlaps at least in some cases.
struct PathBuf
    buf::IOBuffer
end

PathBuf() = PathBuf(IOBuffer())

# TODO: This is certainly not correct in all cases.
function Base.push!(pb::PathBuf, component::String)
    write(pb.buf, component, MAIN_SEPARATOR_STR)
end

Path(pb::PathBuf) = Path(String(take!(pb.buf)))

Base.copy(p::Path) = Path(p.inner)

function isabsolute(p::Path)
    isabspath(p.inner)
end

function isrelative(p::Path)
    !isabsolute(p)
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

# TODO: This includes leading dot on extension
# Rust std::path::extension does not.
# Choose whichever is best for this API.
function extension(p::Path)
    splitext(p)[2]
end

# In Rust std::path `file_prefix`
function fileprefix(p::Path)
    splitext(p)[1]
end

# See std::path::has_root. Not exactly equivalent to `isabsolute`.
function hasroot(p::Path)
    if Sys.isunix()
        isabsolute(p)
    else
        notimplemented()
    end
end

Base.parent(p::Path) = notimplemented()
