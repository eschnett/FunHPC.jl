module Functor

using Funs

export fmap

fmap{FT}(f::Callable, xs::FT, yss...; R::Type=eltype(f)) =
    error("fmap not specialized for type $FT")

# Array
@generated function fmap{T,D}(f::Callable, xs::Array{T,D}, yss::Array...;
        R::Type=eltype(f))
    quote
        tuple($([:(@assert length(yss[$n]) == length(xs))
            for n in 1:length(yss)]...))
        rs = similar(xs, R)
        @inbounds @simd for i in eachindex(xs)
            rs[i] = f(xs[i], $([:(yss[$n][i]) for n in 1:length(yss)]...))
        end
        rs::Array{R,D}
    end
end

# Fun (Callable)
function fmap(f::Callable, fun::Callable, funs::Callable...; R::Type=eltype(f))
    Fun{R}((x,ys...) -> f(fun(x), map((f,y)->f(y), funs, ys)...))
end

# Set
function fmap{T}(f::Callable, xs::Set{T}; R::Type=eltype(f))
    rs = Set{R}()
    for x in xs
        push!(rs, f(x))
    end
    rs::Set{R}
end

# Tuple
@generated function fmap(f::Callable, xs::Tuple, yss::Tuple...;
        R::Type=eltype(f))
    [@assert nfields(yss[n]) == nfields(xs) for n in 1:length(yss)]
    quote
        rs = tuple($([
            quote
                f(xs[$i], $([:(f(yss[$n][$i])) for n in 1:length(yss)]...))
            end
            for i in 1:nfields(xs)]...))
        rs::NTuple{$(nfields(xs)), R}
    end
end

end
