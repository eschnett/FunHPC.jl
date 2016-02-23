module Foldable

using Funs

export freduce

freduce{Z,FT}(f::Callable, zero::Z, xs::FT, yss...; R::Type=eltype(f)) =
    error("freduce not specialized for types ($Z,$FT)")

# Array
@generated function freduce{Z,T,D}(f::Callable, zero::Z, xs::Array{T,D},
        yss::Array...; R::Type=eltype(f))
    quote
        [@assert size(ys) == size(xs) for ys in yss]
        r = zero
        @inbounds #=@simd=# for i in eachindex(xs)
            r = f(r, xs[i], $([:(yss[$n][i]) for n in 1:length(yss)]...))
        end
        r::R
    end
end

# Set
function freduce{Z,T}(f::Callable, zero::Z, xs::Set{T}; R::Type=eltype(f))
    r = zero
    for x in xs
        r = f(r, x)
    end
    r::R
end

# Tuple
@generated function freduce{Z}(f::Callable, zero::Z, xs::Tuple, yss::Tuple...;
        R::Type=eltype(f))
    quote
        [@assert length(ys) == length(xs) for ys in yss]
        r = zero
        @inbounds #=@simd=# for i in eachindex(xs)
            r = f(r, xs[i], $([:(yss[$n][i]) for n in 1:length(yss)]...))
        end
        r::R
    end
end

end
