module Monad

using Functor, Funs

export tycon, valtype
export munit, mjoin, mbind, mzero, mplus

# valtype(tycon(MT, T)) == T
tycon(::Type, ::Type) = error("tycon not specialized")
valtype(::Type) = error("valtype not specialized")

# Monad
munit(::Type, x) = error("munit not specialized")
mjoin(xss) = error("mjoin not specialized")
mbind(xs, f::Callable; R::Type=Any) = error("mbind not specialized")

# MonadPlus
mzero(::Type) = error("mzero not specialized")
mplus(xs, yss...) = error("mplus not specialized")



# Array

tycon{T,D,R}(::Type{Array{T,D}}, ::Type{R}) = Array{R,D}
valtype{T,D}(::Type{Array{T,D}}) = T

munit{T,D}(::Type{Array{T,D}}, x) = fill(x, ntuple(i->1, D))
function mjoin{AT}(xss::Array{AT,0})
    T = eltype(AT)
    @assert AT == Array{T,0}
    xss[1]::Array{T,0}
end
function mjoin{AT}(xss::Array{AT,1})
    T = eltype(AT)
    @assert AT == Array{T,1}
    vcat(xss...)::Array{T,1}
end
function mjoin{AT}(xss::Array{AT,2})
    T = eltype(AT)
    @assert AT == Array{T,2}
    if isempty(xss) return Array(T, (0,0)) end
    s0 = size(xss)
    s1 = size(xss[1])
    sr = map(*, s0, s1)
    rs = Array(T, sr)
    for j0 in 1:s0[2], i0 in 1:s0[1]
        irmin = (i0-1) * s0[1] + 1
        jrmin = (j0-1) * s0[2] + 1
        irmax = (i0-1) * s0[1] + s1[1]
        jrmax = (j0-1) * s0[2] + s1[2]
        rs[irmin:irmax,jrmin:jrmax] = xss[i0,j0]
    end
    rs::Array{T,2}
end
mbind{T,D}(xs::Array{T,D}, f::Callable; R::Type=eltype(f)) =
    mjoin(fmap(R=R, f, xs))

mzero{T,D}(::Type{Array{T,D}}) = Array(T, ntuple(i->0, D))
mplus{T,D}(xs::Array{T,D}, yss::Array{T,D}...) = vcat(xs, yss...)



# Fun (Callable)

tycon{R}(::Type{Callable}, ::Type{R}) = Fun{R}
valtype{T}(::Type{Fun{T}}) = T

munit{T}(::Type{Fun{T}}, x) = Fun{T}(a->x)
mjoin{T}(f::Fun{Fun{T}}) = Fun{T}(x->f(x)(x))
mbind{T}(f::Fun{T}, g::Callable; R::Type=eltype(g)) = mjoin(fmap(R=R, g, f))



# Set

tycon{T,R}(::Type{Set{T}}, ::Type{R}) = Set{R}
valtype{T}(::Type{Set{T}}) = T

munit{T}(::Type{Set{T}}, x) = Set{T}([x])
function mjoin{T}(xss::Set{Set{T}})
    rs = Set{T}()
    for xs in xss
        union!(rs, xs)
    end
    rs::Set{T}
end
mbind{T}(xs::Set{T}, f::Callable; R::Type=eltype(f)) = mjoin(fmap(R=R, f, xs))

mzero{T}(::Type{Set{T}}) = Set{T}()
function mplus{T}(xs::Set{T}, yss::Set{T}...)
    rs = copy(xs)
    for ys in yss
        union!(rs, ys)
    end
    rs::Set{T}
end

end
