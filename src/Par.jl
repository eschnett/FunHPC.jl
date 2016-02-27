module Par

using Comm, GIDs, Foldable, Functor, FunRefs, Funs, Monad

import Base: eltype
import Foldable: freduce
import Functor: fmap
import Monad: tycon, valtype, munit, mjoin, mbind

export par   # @par
export rpar, rcall   # @rpar, @rcall
export make_local, get_remote
export unwrap
export remote   # @remote



# resc(expr) = esc(Base.localize_vars(expr, false))
# # Return an iterable consisting of a Callable and arguments,
# # corresponding to the content of args of a call Expr
# function make_callargs(expr)
#     if false && Funs.iscall(expr)
#         # Optimize calls by not wrapping them in a lambda expression
#         Funs.getcallargs(expr)
#     else
#         {:(()->$expr)}
#     end
# end



function par(f::Callable; R::Type=eltype(f))
    r = FunRef{R}()
    @schedule r[] = f()
    r::FunRef{R}
end

# macro par(args...)
#     if length(args) == 1
#         (expr,) = args
#         resc(:(par(()->$expr)))
#     elseif length(args) == 2
#         (R, expr) = args
#         resc(:(par(R=$R, ()->$expr)))
#     else
#         error("Expected: @par [<type>] <expr>)")
#     end
# end


immutable Item
    item::Any
end

function rpar(f::Callable, ref::FunRef; R::Type=eltype(f))
    r = FunRef{R}()
    rgid = makegid(r)
    @schedule rexec(getproc(ref)) do
        rpar2(rgid, f)
    end
    r::FunRef{R}
end
rpar(f::Callable, p::Integer; R::Type=eltype(f)) = rpar(R=R, f, Int(p))
function rpar(f::Callable, p::Int; R::Type=eltype(f))
    r = FunRef{R}()
    rgid = makegid(r)
    rexec(p) do
        rpar2(rgid, f)
    end
    r::FunRef{R}
end
function rpar2(rgid::GID, f::Callable)
    res = f()
    rexec(rgid.proc) do
        rpar3(rgid, Item(res))
    end
end
function rpar3(rgid::GID, res::Item)
    r = getobj(rgid)
    free(rgid)
    r[] = res.item
end

# TODO: Introduce LocalFunRef (aka Future) that does not obtain a GID for the item
# TODO: Obtain GID lazily, only when needed?
function rcall(f::Callable, p::Union{Integer,FunRef}; R::Type=eltype(f))
    rpar(R=R, f, p)[]::R
end

# macro rpar(args...)
#     if length(args) == 2
#         (p, expr) = args
#         resc(:(rpar(()->$expr, $p)))
#     elseif length(args) == 3
#         (R, p, expr) = args
#         resc(:(rpar(R=$R, ()->$expr, $p)))
#     else
#         error("Expected: @rpar [<type>] <proc> <expr>)")
#     end
# end

# macro rcall(args...)
#     if length(args) == 2
#         (p, expr) = args
#         resc(:(rcall(()->$expr, $p)))
#     elseif length(args) == 3
#         (R, p, expr) = args
#         resc(:(rcall(R=$R, ()->$expr, $p)))
#     else
#         error("Expected: @rcall [<type>] <proc> <expr>)")
#     end
# end



function make_local{R}(ref::FunRef{R})
    rpar(R=R, ref) do
        ref[]
    end::FunRef{R}
end
function get_remote{R}(ref::FunRef{R})
    make_local(ref)[]::R
end



function unwrap(ref::FunRef{Any})
    r = FunRef{Any}()
    rgid = makegid(r)
    @schedule rexec(getproc(ref)) do
        unwrap2(rgid, ref)
    end
    r::FunRef{Any}
end
function unwrap2(rgid::GID, ref::FunRef{Any})
    ref2 = ref[]::FunRef{Any}
    wait(ref2)
    rexec(rgid.proc) do
        unwrap3(rgid, ref2)
    end
end
function unwrap{R}(ref::FunRef{FunRef{R}})
    r = FunRef{R}()
    rgid = makegid(r)
    @schedule rexec(getproc(ref)) do
        unwrap2(rgid, ref)
    end
    r::FunRef{R}
end
function unwrap2{R}(rgid::GID, ref::FunRef{FunRef{R}})
    ref2 = ref[]::FunRef{R}
    wait(ref2)
    rexec(rgid.proc) do
        unwrap3(rgid, ref2)
    end
end
function unwrap3{R}(rgid::GID, ref2::FunRef{R})
    r = getobj(rgid)::FunRef{R}
    free(rgid)
    set_from_ref!(r, ref2)
end



function remote(f::Callable, ref::FunRef; R::Type=eltype(f))
    r = FunRef{R}()
    rgid = makegid(r)
    @schedule rexec(getproc(ref)) do
        remote2(R, rgid, f)
    end
    r::FunRef{R}
end
remote(f::Callable, p::Integer; R::Type=eltype(f)) = remote(f, Int(p), R=R)
function remote(f::Callable, p::Int; R::Type=eltype(f))
    r = FunRef{R}()
    rgid = makegid(r)
    rexec(p) do
        remote2(R, rgid, f)
    end
    r::FunRef{R}
end
function remote2(R::Type, rgid::GID, f::Callable)
    ref = FunRef{R}(f())
    rexec(rgid.proc) do
        remote3(rgid, Item(ref))
    end
end
function remote3(rgid::GID, ref::Item)
    r = getobj(rgid)
    free(rgid)
    set_from_ref!(r, ref.item::FunRef)
end

# macro remote(args...)
#     if length(args) == 2
#         (p, expr) = args
#         resc(:(remote(()->$expr, $p)))
#     elseif length(args) == 3
#         (R, p, expr) = args
#         resc(:(remote(R=$R, ()->$expr, $p)))
#     else
#         error("Expected: @remote [<type>] <proc> <expr>)")
#     end
# end



# FunRef is Foldable, Functor, Applicative, and Monad

@generated function freduce(op::Callable, zero, ref::FunRef, refs::FunRef...;
        R::Type=eltype(op))
    quote
        rcall(R=R, ref) do
            op(zero, ref[],
                $([:(get_remote(refs[$i])) for i in 1:length(refs)]...))
        end
    end
end

@generated function fmap(f::Callable, ref::FunRef, refs::FunRef...;
        R::Type=eltype(f))
    quote
        remote(R=R, ref) do
            f(ref[], $([:(get_remote(refs[$i])) for i in 1:length(refs)]...))
        end
    end
end

tycon{T,R}(::Type{FunRef{T}}, ::Type{R}) = FunRef{R}
valtype{T}(::Type{FunRef{T}}) = T

munit{T}(::Type{FunRef{T}}, x) = FunRef{T}(x)
mjoin{T}(xss::FunRef{FunRef{T}}) = unwrap(xss)
function mbind{T}(f::Callable, xs::FunRef{T}; R::Type=eltype(f))
    mjoin(fmap(R=R, f, xs))
end

end
