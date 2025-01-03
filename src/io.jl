function Base.open(path::Path; kwargs...)
    Base.open(String(path); kwargs...)
end

function Base.open(path::Path, mode::AbstractString; kwargs...)
    Base.open(String(path), mode; kwargs...)
end

function Base.read(path::Path, args...)
    Base.read(String(path), args...)
end

function Base.read!(path::Path, a)
    Base.read!(String(path), a)
end

function Base.readuntil(path::Path, delim; kwargs...)
    Base.readuntil(String(path), delim; kwargs...)
end

function Base.write(path::Path, content, args...)
    Base.write(String(path), content, args...)
end

function Base.copyuntil(out::IO, path::Path, delim; kw...)
    Base.copyuntil(out, String(path), delim; kw...)
end

function Base.readline(path::Path; keep::Bool=false)
    Base.readline(String(path); keep=keep)
end

# copyline
