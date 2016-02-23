module StencilFunctor

using Funs

export stencil_fmap

stencil_fmap{FT,C}(f::Callable, g::Callable, xs::FT, bm::C, bp::C;
                   R::Type=eltype(f)) =
    error("stencil_fmap not specialized for type $FT")



# Array

function stencil_fmap{T,C}(f::Callable, g::Callable,
                           xs::Vector{T}, bm::C, bp::C; R::Type=eltype(f))
    s = length(xs)
    rs = similar(xs, R)
    if s == 0
        # do nothing
    elseif s == 1
        @inbounds rs[1] = call(R=R, f, xs[1], bm, bp)
    else
        @inbounds rs[1] = call(R=R, f, xs[1], bm, call(R=C, g, xs[2], false))
        @simd for i in 2:s-1
            @inbounds rs[i] = call(R=R, f, xs[i],
                                   call(R=C, g, xs[i-1], true),
                                   call(R=C, g, xs[i+1], false))
        end
        @inbounds rs[s] = call(R=R, f, xs[s], call(R=C, g, xs[s-1], true), bp)
    end
    rs::Vector{R}
end

end
