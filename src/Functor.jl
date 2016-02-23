module Functor

using Funs

export fmap

fmap{FT}(f::Callable, xs::FT, yss...; R::Type=eltype(f)) =
    error("fmap not specialized for type $FT")

# Array
@generated function fmap{T,D}(f::Callable, xs::Array{T,D}, yss::Array...;
        R::Type=eltype(f))
    quote
        [@assert size(ys) == size(xs) for ys in yss]
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
function fmap(f::Callable, xs::Tuple, yss::Tuple...; R::Type=eltype(f))
    [@assert length(ys) == length(xs) for ys in yss]
    map(f, xs, yss...)::NTuple{length(xs), R}
end

end
